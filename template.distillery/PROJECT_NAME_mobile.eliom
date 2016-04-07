[%%client
[@@@ocaml.warning "-33"]
open %%%MODULE_NAME%%% (* for dependency reasons *)
[@@@ocaml.warning "+33"]
]

[%%client
open Eliom_content.Html5
open Eliom_content.Html5.F
]

let%server init_request _myid_o () =
  (* Empty server-side RPC. You can add your own action to perform server-side
   * on first client request. *)
  Lwt.return ()

let%server init_request_rpc : (_, unit) Eliom_client.server_function =
  Eliom_client.server_function ~name:"%%%MODULE_NAME%%%_mobile.init_request_rpc"
    [%derive.json: unit]
    (Eba_session.Opt.connected_rpc init_request)

let%client _ =
  if Eliom_client.is_client_app ()
  then begin
    (* Initialize the application server-side;
       there should be a single initial request for that. *)
    let%lwt _ = Lwt_js_events.onload () in
    let%lwt _ = ~%init_request_rpc () in
    (* Eliom_client.change_page ~service:Eba_services.event_service 66347L () *)
    Eliom_client.change_page ~service:Eba_services.main_service () ()
  end
  else Lwt.return ()

let%client () = Eliom_config.debug_timings := true
let%client () = Lwt_log_core.add_rule "eliom:client*" Lwt_log.Debug
let%client () = Lwt_log_core.add_rule "eba*" Lwt_log.Debug

let%client add_listeners () =
  let activate ev =
    ignore @@ Dom.addEventListener Dom_html.document ev
      (Dom_html.handler (fun _ -> Eliom_comet.activate (); Js._true)) Js._false
  in
  activate (Dom_html.Event.make "online");
  activate (Dom_html.Event.make "resume")
    (* FIX: idle mode on offline/pause events? *)

let%client _ =
  Dom.addEventListener Dom_html.document (Dom_html.Event.make "deviceready")
    (Dom_html.handler (fun _ -> add_listeners (); Js._true)) Js._false
