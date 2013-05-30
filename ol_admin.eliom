open Ol_db
open Eliom_content.Html5.F

(* Admin section *)
exception Not_admin

let admin_service =
  Eliom_service.service
    ~path:["admin"]
    ~get_params:Eliom_parameter.unit ()

let admin_page_content () =
  let state_to_string = function
    | WIP -> "work in progress"
    | Production -> "on production"
    | Unknown -> "??"
  in
  lwt state = Ol_db.get_state_of_site () in
    Lwt.return
      ([p [pcdata "welcome admin"];
           p [pcdata (state_to_string state)]])

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
   (* should be handle with an exception caught in the Connection_Wrapper ?
    * or just return some html5 stuffs to tell that the user can't reach this
    * page ? (404 ?) *)
  then Lwt.fail Not_admin
  else
    lwt content = admin_page_content () in
    Lwt.return
      (match container with
         | Some container -> (container content)
         | None -> admin_page_container content)
