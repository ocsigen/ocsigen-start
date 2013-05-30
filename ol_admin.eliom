open Eliom_content.Html5.F

(* Admin section *)
exception Not_admin

let admin_service =
  Eliom_service.service
    ~path:["admin"]
    ~get_params:Eliom_parameter.unit ()

let admin_page_content =
      [p [pcdata "welcome admin"]]

(** default page container for the admin page,
  * it will be use by admin_service handler by default *)
let admin_page_container content =
    let css = [["eliom_ui.css"]; ["ol.css"]] in
    let js = [["jquery.js"]] in
    (html
       (Eliom_tools.F.head ~title:"OL Admin page" ~css ~js ())
       (body content))

let admin_service_handler ?(container) uid () () =
  lwt user = Ol_db.get_user uid in
  if not (Ol_common0.is_admin user)
  then Lwt.fail Not_admin
  else
    Lwt.return
      (match container with
         | Some container -> (container admin_page_content)
         | None -> admin_page_container admin_page_content)
