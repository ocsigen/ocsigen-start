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

[%%shared
  open Eliom_content.Html
  open Eliom_content.Html.F
]

let%shared __link = () (* to make sure os_comet is linked *)

let%client restart_process () =
  if Eliom_client.is_client_app () then
    Eliom_client.exit_to ~absolute:false
      ~service:(Eliom_service.static_dir ())
      ["index.html"] ()
  else
    Eliom_client.exit_to ~service:Eliom_service.reload_action () ()


let%client _ = Eliom_comet.set_handle_exn_function
    (fun ?exn () -> restart_process (); Lwt.return ())




(* We create a channel on scope user_indep_process_scope,
   to monitor the application.
   If this channel is closed or fails, it means that something went wrong.
*)

[%%shared
  type msg = Connection_changed | Heartbeat
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

let%client handle_message = function
  | Lwt_stream.Error exn ->
    Eliom_lib.debug_exn
      "Exception received on Os_comet's monitor channel: " exn;
    restart_process ();
    Lwt.return ()
  | Lwt_stream.Value Heartbeat ->
    Eliom_lib.debug "poum";
    Lwt.return ()
  | Lwt_stream.Value Connection_changed ->
    Os_msg.msg ~level:`Err
      "Connection has changed from outside. Program will restart.";
    let%lwt () = Lwt_js.sleep 2. in
    Eliom_client.exit_to ~service:Eliom_service.reload_action () ();
    Lwt.return ()

let _ =
  Os_session.on_start_process
    (fun () ->
       let channel = create_monitor_channel () in
       Eliom_reference.Volatile.set monitor_channel_ref (Some channel);
       ignore [%client ( Lwt.async (fun () ->
         Lwt_stream.iter_s
           handle_message
           (Lwt_stream.map_exn ~%(fst channel))) : unit)];
       Lwt.return ());
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
    Lwt.return ()
  in
  let warn_connection_change _ = warn Connection_changed in
  Os_session.on_open_session warn_connection_change;
  Os_session.on_post_close_session warn_connection_change
