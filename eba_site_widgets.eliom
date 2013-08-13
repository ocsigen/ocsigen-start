(* Copyright Vincent Balat *)

(** This module defines specific Ol site widgets *)

{shared{
open Eliom_content
open Eliom_content.Html5
open Eliom_content.Html5.F
}}

let class_globalpart = "ol_globalpart"
let class_identity = "ol_identity"
let class_mainpart = "ol_mainpart"
let class_main_infobox = "ol_main_infobox"

{client{
  let global_widget_set = Ew_button.new_radio_set ()
}}

{client{

  let info ?important ?class_ ?timeout msg =
    Eba_misc.log msg
(*INFOBOX
    Lwt.async
      (fun () -> lwt infobox_o = infobox_o_t in
                 infobox_o#info ?class_ ?important ?timeout msg;
                 Lwt.return ())
*)

}}

let main_title capitalized_app_name =
  let title =
    Eliom_content.Html5.Id.create_global_elt
      (D.h1 [a ~service:Eba_services.main_service
                [pcdata capitalized_app_name] ()])
  in
  ignore {unit{
    Eliom_client.onload
      (fun () ->
        let t = To_dom.of_h1 %title in
        Lwt_js_events.async (fun () ->
          Lwt_js_events.clicks t (fun ev _ ->
            Dom.preventDefault ev;
            info "Ocsigen Labs";
            Lwt.return ())))
  }};
  title

let logout_button () =
  (* let b = D.div ~a:[a_class ["ol_logout_button"]] [pcdata "O"] in *)
  let b = D.div ~a:[a_class ["ol_logout_button"]]
    [i ~a:[a_class ["icon-signout"]] []]
  in
  ignore {unit{
    Lwt_js_events.async (fun () ->
      Lwt_js_events.clicks (To_dom.of_div %b)
        (fun _ _ -> Eliom_client.change_page %Eba_services.logout_service () ()))
    }};
  b

let default_settings_box user =
  (*
  lwt admin_g = Eba_groups.admin in
  lwt is_admin =
    Eba_groups.in_group
      ~userid:(Eba_common0.id_of_user user)
      ~group:admin_g
  in
   *)
  let is_admin = true in
  let l = [hr ();
           Eba_base_widgets.password_form ();
           hr ();
           logout_button ()]
  in
  let l =
    if is_admin
    then F.a ~service:Eba_services.admin_service [pcdata "admin page"] ()::l
    else l
  in
  Lwt.return l

let _ = Eba_settings.set_content default_settings_box

let userbox user =
  lwt settings = Eba_settings.create_box user in
  Lwt.return
    (div ~a:[a_class [class_identity]] [
      Eba_user.print_user_avatar user;
      Eba_picture_box.create user;
      Eba_user.print_user_name user;
      settings
    ])

let globalpart main_title user =
(*INFOBOX
  let infobox = Eliom_widgets.infobox_elts ~class_:[class_main_infobox] () in
  ignore
    {unit{ REIMPLEMENT
        (new Eliom_widgets.infobox ~multiline:true ~timeout:10. %infobox)}};
*)
  lwt content = match user with
    | Some user ->
      lwt ubox = userbox user in
      Lwt.return [ubox(*; infobox *)]
    | None ->
      lwt cbox = Eba_base_widgets.login_signin_box () in
      Lwt.return [cbox(* infobox *)]
  in
  Lwt.return
    (aside ~a:[a_class [class_globalpart]]
       (main_title
        ::content))


let mainpart ?(class_=[]) l = div ~a:[a_class (class_mainpart::class_)] l
