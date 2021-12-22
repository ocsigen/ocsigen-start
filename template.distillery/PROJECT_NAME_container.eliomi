(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)

[%%shared.start]

(** This module defines the default template for application pages *)

val os_header
  :  ?user:Os_types.User.t
  -> unit
  -> [> `Header] Eliom_content.Html.F.elt Lwt.t
(** [os_header ?user ()] defines the header for all pages. In this
    template, it's a userbox and the user name is displayed. *)

val os_footer : unit -> [> `Footer] Eliom_content.Html.F.elt
(** [os_footer ()] defines a footer for the page. *)

val connected_welcome_box
  :  unit
  -> [> Html_types.div] Eliom_content.Html.F.elt Lwt.t

val get_user_data : Os_types.User.id option -> Os_types.User.t option Lwt.t

val page
  :  ?html_a:Html_types.html_attrib Eliom_content.Html.attrib list
  -> ?a:Html_types.body_attrib Eliom_content.Html.attrib list
  -> ?title:string
  -> ?head:[< Html_types.head_content_fun] Eliom_content.Html.elt list
  -> Os_types.User.id option
  -> [< Html_types.div_content_fun > `Div] Eliom_content.Html.F.elt
     Eliom_content.Html.F.list_wrap
  -> Os_page.content Lwt.t
(** [page userid_o content] returns a page personalized for the user
    with id [myid_o] and with the content [content]. It adds a header,
    a footer, and a drawer menu.  If the user profile is not
    completed, a connected welcome box is added. *)

[%%shared.start]

val get_wrong_pdata
  :  unit
  -> ((string * string) * (string * string)) option Lwt.t
