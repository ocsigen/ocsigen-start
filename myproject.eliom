(* Copyright Vincent Balat *)

(** Main module. Web interaction.
    Definition of service handlers and registration of services. *)
{shared{
open Eliom_content.Html5
open Eliom_content.Html5.F

(* SSS Do not compiles after a distclean if you remove me *)
module O = Ol_common0
}}


(********* Service handlers *********)

let main_service_handler userid () () =
  lwt user = Ol_db.get_user userid in
  let mainpart = if (Myproject_sessions.new_user user)
    then [Ol_base_widgets.welcome_box ()]
    else []
  in
  Lwt.return (Myproject_sessions.page_container
                (Ol_site_widgets.globalpart
                   Myproject_sessions.main_title (Some user)
                 ::mainpart))


(********* Registration *********)
let _ =
  Myproject_sessions.My_appl.register Ol_services.main_service
    (Myproject_sessions.connect_wrapper_page main_service_handler);


{client{

  let () = Eliom_config.debug_timings := true
}}
