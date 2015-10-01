(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
 *
 * Copyright 2014
 *      Vincent Balat
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

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F

  let __link = () (* to make sure eba_comet is linked *)
}}

{client{
  (* This will show a message saying that client process is closed *)
  let close_client_process ?exn () =
    Eliom_lib.Option.iter
      (Eliom_lib.debug_exn "EBA: Exception on channel - ") exn;
    let d =
      D.div ~a:[a_class ["eba_process_closed"]] [
        img ~alt:("Ocsigen Logo")
          ~src:(Xml.uri_of_string
                  "http://ocsigen.org/resources/logos/ocsigen_with_shadow.png")
          ();
        p [
          pcdata "Ocsigen process in eco-friendly mode.";
          br ();
          a ~xhr:false
            ~service:Eliom_service.void_coservice'
            [pcdata "Click"]
            ();
          pcdata " to wake up."
        ];
      ]
    in
    let d = To_dom.of_div d in
    Dom.appendChild (Dom_html.document##body) d;
    lwt () = Lwt_js_events.request_animation_frame () in
    d##style##backgroundColor <- Js.string "rgba(255, 255, 255, 0.8)";
    (* I put both a handler on click and not focus.
       Sometimes the window hasn't lost focus, thus focus is not enough.
    *)
    Lwt.async (fun () ->
      lwt _ = Lwt_js_events.click Dom_html.document in
      Eliom_client.exit_to ~service:Eliom_service.void_coservice' () ();
      Lwt.return ()
    );
    (* Lwt.async (fun () -> *)
    (*   lwt _ = Lwt_js_events.focus Dom_html.window in *)
    (*   Eliom_client.exit_to ~service:Eliom_service.void_coservice' () (); *)
    (*   Lwt.return () *)
    (* ); *)
    Lwt.return ()

let _ = Eliom_comet.set_handle_exn_function close_client_process

}}



(* We create a channel on scope user_indep_process_scope,
   to monitor the application.
   If this channel is closed or fails, it means that something went wrong.
*)

{shared{
type msg = Connection_changed | Heartbeat
 }}

let create_monitor_channel () =
  let monitor_stream, monitor_send = Lwt_stream.create () in
  let channel = Eliom_comet.Channel.create
      ~scope:Eba_session.user_indep_process_scope
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
    ~scope:Eba_session.user_indep_process_scope
    None

let already_send_ref =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

{client{

   let handle_message = function
     | Lwt_stream.Error exn ->
       Eliom_lib.debug_exn
         "Exception received on Eba_comet's monitor channel: " exn;
       close_client_process () (* or exit_to? *)
     | Lwt_stream.Value Heartbeat ->
       Eliom_lib.debug "poum";
       Lwt.return ()
     | Lwt_stream.Value Connection_changed ->
       Eba_msg.msg ~level:`Err
         "Connection has changed from outside. Program will restart.";
       lwt () = Lwt_js.sleep 2. in
       Eliom_client.exit_to ~service:Eliom_service.void_coservice' () ();
       Lwt.return ()

}}

let _ =
  Eba_session.on_start_process
    (fun () ->
       let channel = create_monitor_channel () in
       Eliom_reference.Volatile.set monitor_channel_ref (Some channel);
       ignore {unit{ Lwt.async (fun () ->
         Lwt_stream.iter_s
           handle_message
           (Lwt_stream.map_exn %(fst channel))) }};
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
                  ~scope:Eba_session.user_indep_session_scope ())
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
  Eba_session.on_open_session warn_connection_change;
  Eba_session.on_post_close_session warn_connection_change
