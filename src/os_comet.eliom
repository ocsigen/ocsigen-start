(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright (C) Université Paris Diderot, CNRS, INRIA, Be Sport.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

open%shared Eliom_content.Html
open%shared Eliom_content.Html.F
open%client Js_of_ocaml
open%client Js_of_ocaml_lwt

let%shared __link = () (* to make sure os_comet is linked *)


let%client cookies_enabled () =
  try
    Dom_html.document##.cookie := Js.string "cookietest=1";
    let has_cookies =
      Dom_html.document##.cookie##indexOf (Js.string "cookietest=") <> -1 in
    Dom_html.document##.cookie :=
      Js.string "cookietest=1; expires=Thu, 01-Jan-1970 00:00:01 GMT";
    has_cookies
  with _ ->
    false




let%client restart_process () =
  if Eliom_client.is_client_app () then
    Eliom_client.exit_to ~absolute:false
      ~service:(Eliom_service.static_dir ())
      ["index.html"] ()
  else
    (* If cookies do not work,
       the failed comet is probably due to missing cookies.
       In that case we do not restart. This happens for example
       if cookies are deactivated of if the app is running in an iframe
       and the browser forbids third party cookies. *)
  if cookies_enabled ()
  then Eliom_client.exit_to ~service:Eliom_service.reload_action () ()


let%client _ = Eliom_comet.set_handle_exn_function
    (fun ?exn () -> restart_process (); Lwt.return_unit)




(* We create a channel on scope user_indep_process_scope,
   to monitor the application.
   If this channel is closed or fails, it means that something went wrong.
*)

[%%shared
(** The type of sent message *)
type msg =
  | Connection_changed (** If a connection changed *)
  | Heartbeat (** Just to be sure the server is not down. *)
]

let create_monitor_channel () =
  let monitor_stream, monitor_send = Lwt_stream.create () in
  let channel = Eliom_comet.Channel.create
      ~scope:Os_session.user_indep_process_scope
      ~name:"monitor"
      monitor_stream
  in
  channel, monitor_send

(* The monitor channel for each browser tab is kept in a client-process
   reference that remains even if user logs out (user_indep_process_scope)
   (so that it is not garbage collected).
   It is garbage collected when this client process state is closed
   after timeout.
 *)
let monitor_channel_ref =
  Eliom_reference.Volatile.eref
    ~scope:Os_session.user_indep_process_scope
    None

let already_send_ref =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let%client handle_error =
  ref
    (fun exn ->
      Eliom_lib.debug_exn
        "Exception received on Os_comet's monitor channel: " exn;
      restart_process ();
      Lwt.return_unit)

let%client set_error_handler f = handle_error := f

let%client handle_message = function
  | Lwt_stream.Error exn ->
    !handle_error exn
  | Lwt_stream.Value Heartbeat ->
    Eliom_lib.debug "poum";
    Lwt.return_unit
  | Lwt_stream.Value Connection_changed ->
    Os_msg.msg ~level:`Err
      "Connection has changed from outside. Program will restart.";
    let%lwt () = Lwt_js.sleep 2. in
    restart_process ();
    Lwt.return_unit

let%server warn_state c state =
  match Eliom_reference.Volatile.Ext.get state monitor_channel_ref with
  | Some (_, send) as v -> send (Some c)
  | None -> ()

let%server _ =
  Os_session.set_warn_connection_change (warn_state Connection_changed)

let%server _ =
  Os_session.on_start_process
    (fun _ ->
       let channel = create_monitor_channel () in
       Eliom_reference.Volatile.set monitor_channel_ref (Some channel);
       ignore [%client ( Lwt.async (fun () ->
         Lwt_stream.iter_s
           handle_message
           (Lwt_stream.map_exn ~%(fst channel))) : unit)];
       Lwt.return_unit);
  let warn c =
    (* User connected or disconnected.
       I want to send the message on all tabs of the browser: *)
    if not (Eliom_reference.Volatile.get already_send_ref)
    then begin
      Eliom_reference.Volatile.set already_send_ref true;
      let cur = Eliom_reference.Volatile.get monitor_channel_ref in
      Eliom_state.Ext.iter_volatile_sub_states
        ~state:(Eliom_state.Ext.current_volatile_session_state
                  ~scope:Os_session.user_indep_session_scope ())
        (fun state ->
           match
             Eliom_reference.Volatile.Ext.get state monitor_channel_ref with
           | Some (_, send) as v ->
             if not (v == cur) then send (Some c)
           | None -> ())
    end;
    Lwt.return_unit
  in
  let warn_connection_change _ = warn Connection_changed in
  Os_session.on_open_session warn_connection_change;
  Os_session.on_post_close_session warn_connection_change
