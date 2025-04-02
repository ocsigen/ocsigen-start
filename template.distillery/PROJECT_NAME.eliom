open%shared Lwt.Syntax

(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)

let%client add_email_notif () = ()

let%server add_email_notif () =
  if Eliom_reference.Volatile.get Os_user.user_already_exists
  then Os_msg.msg ~level:`Err ~onload:true [%i18n S.email_already_exists]

let%shared () =
  (* Registering services. Feel free to customize handlers. *)
  Eliom_registration.Action.register
    ~service:Os_services.set_personal_data_service
    %%%MODULE_NAME%%%_handlers.set_personal_data_handler;
  Eliom_registration.Redirection.register
    ~service:Os_services.set_password_service
    %%%MODULE_NAME%%%_handlers.set_password_handler;
  Eliom_registration.Action.register
    ~service:Os_services.forgot_password_service
    %%%MODULE_NAME%%%_handlers.forgot_password_handler;
  Eliom_registration.Action.register ~service:Os_services.preregister_service
    %%%MODULE_NAME%%%_handlers.preregister_handler;
  Eliom_registration.Action.register ~service:Os_services.sign_up_service
    Os_handlers.sign_up_handler;
  Eliom_registration.Action.register ~service:Os_services.connect_service
    Os_handlers.connect_handler;
  Eliom_registration.Unit.register ~service:Os_services.disconnect_service
    (Os_handlers.disconnect_handler ~main_page:true);
  Eliom_registration.Any.register ~service:Os_services.action_link_service
    (Os_session.Opt.connected_fun %%%MODULE_NAME%%%_handlers.action_link_handler);
  Eliom_registration.Action.register ~service:Os_services.add_email_service
    (fun () email ->
       let* () = Os_handlers.add_email_handler () email in
       add_email_notif (); Lwt.return_unit);
  Eliom_registration.Action.register
    ~service:Os_services.update_language_service
    %%%MODULE_NAME%%%_handlers.update_language_handler;
  %%%MODULE_NAME%%%_base.App.register ~service:Os_services.main_service
    (%%%MODULE_NAME%%%_page.Opt.connected_page
       %%%MODULE_NAME%%%_handlers.main_service_handler);
  %%%MODULE_NAME%%%_base.App.register ~service:%%%MODULE_NAME%%%_services.about_service
    (%%%MODULE_NAME%%%_page.Opt.connected_page %%%MODULE_NAME%%%_handlers.about_handler);
  %%%MODULE_NAME%%%_base.App.register ~service:%%%MODULE_NAME%%%_services.settings_service
    (%%%MODULE_NAME%%%_page.Opt.connected_page %%%MODULE_NAME%%%_handlers.settings_handler)

let%server () =
  Eliom_registration.Ocaml.register
    ~service:%%%MODULE_NAME%%%_services.upload_user_avatar_service
    (Os_session.connected_fun %%%MODULE_NAME%%%_handlers.upload_user_avatar_handler)

(* Print more debugging information when <debugmode/> is in config file
   (DEBUG = yes in Makefile.options).
   Example of use:
   let section = Lwt_log.Section.make "%%%MODULE_NAME%%%:sectionname"
   ...
   Lwt_log.ign_info ~section "This is an information";
   (or ign_debug, ign_warning, ign_error etc.)
*)
let%server _ =
  if Eliom_config.get_debugmode ()
  then (
    ignore
      [%client
        ((* Eliom_config.debug_timings := true; *)
         (* Lwt_log_core.add_rule "eliom:client*" Lwt_log_js.Debug; *)
         (* Lwt_log_core.add_rule "os*" Lwt_log_js.Debug; *)
         Lwt_log_core.add_rule "%%%MODULE_NAME%%%*" Lwt_log_js.Debug
         (* Lwt_log_core.add_rule "*" Lwt_log_js.Debug *)
         : unit)];
    (* Lwt_log_core.add_rule "*" Lwt_log.Debug *)
    Lwt_log_core.add_rule "%%%MODULE_NAME%%%*" Lwt_log.Debug)

(* The modules below are all the modules that needs to be explicitely
   linked-in. *)

[%%shared.start]

module Demo = Demo
module Demo_cache = Demo_cache
module Demo_calendar = Demo_calendar
module Demo_carousel1 = Demo_carousel1
module Demo_carousel2 = Demo_carousel2
module Demo_carousel3 = Demo_carousel3
module Demo_i18n = Demo_i18n
module Demo_links = Demo_links
module Demo_notif = Demo_notif
module Demo_pagetransition = Demo_pagetransition
module Demo_pgocaml = Demo_pgocaml
module Demo_popup = Demo_popup
module Demo_pulltorefresh = Demo_pulltorefresh
module Demo_react = Demo_react
module Demo_ref = Demo_ref
module Demo_rpc = Demo_rpc
module Demo_spinner = Demo_spinner
module Demo_timepicker = Demo_timepicker
module Demo_tips = Demo_tips
module Demo_tongue = Demo_tongue
module Demo_users = Demo_users
module %%%MODULE_NAME%%%_config = %%%MODULE_NAME%%%_config

[%%client.start]

module %%%MODULE_NAME%%%_language = %%%MODULE_NAME%%%_language
module %%%MODULE_NAME%%%_mobile = %%%MODULE_NAME%%%_mobile
module %%%MODULE_NAME%%%_phone_connect = %%%MODULE_NAME%%%_phone_connect
