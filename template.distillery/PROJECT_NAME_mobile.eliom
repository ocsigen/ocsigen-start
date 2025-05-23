(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)

[%%client.start]
[%%client open Lwt.Syntax]
[%%client open Js_of_ocaml]
[%%client open Js_of_ocaml_lwt]

(* This RPC is called when client application is initialized. This
   way, the server sends necessary cookies to the client (the mobile
   app) early on and subsequent requests from the client will contain
   the proper cookies.

   The RPC only initializes Os_date by default, but you can add your
   own actions to be performed server side on first client request, if
   necessary. *)
let%rpc init_request myid_o (tz : string) : unit Lwt.t =
  ignore myid_o; Os_date.initialize tz; Lwt.return_unit

let to_lwt f =
  let wait, wakeup = Lwt.wait () in
  f (Lwt.wakeup wakeup);
  wait

let ondeviceready =
  to_lwt (fun cont ->
    ignore
    @@ Js_of_ocaml.Dom.addEventListener Js_of_ocaml.Dom_html.document
         (Js_of_ocaml.Dom_html.Event.make "deviceready")
         (Js_of_ocaml.Dom_html.handler (fun _ -> cont (); Js_of_ocaml.Js._true))
         Js_of_ocaml.Js._false)

let app_started = ref false
let initial_change_page = ref None

let change_page_gen action =
  if !app_started
  then Lwt.async action
  else if !initial_change_page = None
  then initial_change_page := Some action

let change_page_uri uri =
  change_page_gen (fun () -> Eliom_client.change_page_uri uri)

let handle_initial_url () =
  let tz = Os_date.user_tz () in
  let* () = init_request tz in
  let* () = ondeviceready in
  app_started := true;
  match !initial_change_page with
  | None ->
      Eliom_client.change_page ~replace:true ~service:Os_services.main_service
        () ()
  | Some action -> action ()

let () =
  Lwt.async @@ fun () ->
  if Eliom_client.is_client_app ()
  then (
    (* Initialize the application server-side; there should be a
       single initial request for that. *)
    Os_date.disable_auto_init ();
    let* _ = Lwt_js_events.onload () in
    handle_initial_url ())
  else Lwt.return_unit

(* Reactivate comet on resume and online events *)

let () =
  Console.console##log (Js_of_ocaml.Js.string "adding resume/online listeners");
  let activate ev =
    ignore
    @@ Js_of_ocaml.Dom.addEventListener Js_of_ocaml.Dom_html.document
         (Js_of_ocaml.Dom_html.Event.make ev)
         (Js_of_ocaml.Dom_html.handler (fun _ ->
            Console.console##log (Js_of_ocaml.Js.string ev);
            Eliom_comet.activate ();
            Js_of_ocaml.Js._true))
         Js_of_ocaml.Js._false
  in
  activate "online"; activate "resume"

(* Restart on a given URL *)

let storage () =
  Js_of_ocaml.Js.Optdef.case
    Js_of_ocaml.Dom_html.window##.localStorage
    (fun () -> failwith "Browser storage not supported")
    (fun v -> v)

let () =
  let st = storage () in
  let lc = Js_of_ocaml.Js.string "__os_restart_url" in
  Js_of_ocaml.Js.Opt.case
    (st##getItem lc)
    (fun () -> ())
    (fun url ->
       st##removeItem lc;
       change_page_uri (Js_of_ocaml.Js.to_string url))

(* Handle universal links *)

type event =
  < url : Js_of_ocaml.Js.js_string Js_of_ocaml.Js.t Js_of_ocaml.Js.readonly_prop
  ; scheme :
      Js_of_ocaml.Js.js_string Js_of_ocaml.Js.t Js_of_ocaml.Js.readonly_prop
  ; host :
      Js_of_ocaml.Js.js_string Js_of_ocaml.Js.t Js_of_ocaml.Js.readonly_prop
  ; path :
      Js_of_ocaml.Js.js_string Js_of_ocaml.Js.t Js_of_ocaml.Js.readonly_prop
  ; params : 'a. 'a Js_of_ocaml.Js.t Js_of_ocaml.Js.readonly_prop >

let universal_links () =
  let* () = ondeviceready in
  Lwt.return @@ Js_of_ocaml.Js.Optdef.to_option
  @@ (Js_of_ocaml.Js.Unsafe.global##.universalLinks
      : < subscribe :
            Js_of_ocaml.Js.js_string Js_of_ocaml.Js.opt
            -> (event Js_of_ocaml.Js.t -> unit) Js_of_ocaml.Js.callback
            -> unit Js_of_ocaml.Js.meth
        ; unsubscribe :
            Js_of_ocaml.Js.js_string Js_of_ocaml.Js.opt
            -> unit Js_of_ocaml.Js.meth >
          Js_of_ocaml.Js.t
          Js_of_ocaml.Js.Optdef.t)

let _ =
  Lwt.bind (universal_links ()) (function
    | Some universal_links ->
        Js_of_ocaml.Console.console##log
          (Js_of_ocaml.Js.string "Universal links: registering");
        universal_links##subscribe Js_of_ocaml.Js.null
          (Js_of_ocaml.Js.wrap_callback (fun (ev : event Js_of_ocaml.Js.t) ->
             Js_of_ocaml.Console.console##log_2
               (Js_of_ocaml.Js.string "Universal links: got link")
               ev##.url;
             change_page_uri (Js_of_ocaml.Js.to_string ev##.url)));
        Js_of_ocaml.Console.console##log
          (Js_of_ocaml.Js.string "Universal links: registered");
        Lwt.return_unit
    | None -> Lwt.return_unit)

(* Debugging *)

(* Enable debugging messages.

   If you need to display debugging messages in the client side JS
   debugger console, you can do so by uncommenting the following
   lines.  *)
(* let () = Eliom_config.debug_timings := true *)
(* let () = Lwt_log_core.add_rule "eliom:client*" Lwt_log_js.Debug *)
(* let () = Lwt_log_core.add_rule "os*" Lwt_log_js.Debug *)
