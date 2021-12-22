[%%client
(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)

(* RPC button demo *)

open Js_of_ocaml_lwt]

(* Service for this demo *)
let%server service =
  Eliom_service.create
    ~path:(Eliom_service.Path ["demo-rpc"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

(* Make service available on the client *)
let%client service = ~%service
(* Name for demo menu *)
let%shared name () = [%i18n Demo.S.rpc_button]
(* Class for the page containing this demo (for internal use) *)
let%shared page_class = "os-page-demo-rpc"

(* A server-side reference that stores data for the current browser
   (scope = session).
   It's also possible to define Eliom references with other scopes,
   like client-process (a tab of a browser) or session-group (a user).
 *)
let%server my_ref =
  Eliom_reference.eref ~scope:Eliom_common.default_session_scope 0

(* Server-side function that increments my_ref and returns new val *)
let%rpc incr_my_ref () : int Lwt.t =
  let%lwt v = Eliom_reference.get my_ref in
  let v = v + 1 in
  let%lwt () = Eliom_reference.set my_ref v in
  Lwt.return v

let%shared button msg f =
  let btn =
    Eliom_content.Html.(D.button ~a:[D.a_class ["button"]] [D.txt msg])
  in
  ignore
    [%client
      (Lwt.async @@ fun () ->
       Lwt_js_events.clicks (Eliom_content.Html.To_dom.of_element ~%btn)
         (fun _ _ -> ~%f ())
        : unit)];
  btn

(* Page for this demo *)
let%shared page () =
  let btn =
    button [%i18n Demo.S.rpc_button_click_increase]
      [%client
        (fun () ->
           let%lwt v = incr_my_ref () in
           Eliom_lib.alert "Update: %d" v;
           Lwt.return_unit
          : unit -> unit Lwt.t)]
  in
  Lwt.return
    Eliom_content.Html.
      [ F.h1 [%i18n Demo.rpc_button]
      ; F.p [F.txt [%i18n Demo.S.rpc_button_description]]
      ; F.p [btn] ]
