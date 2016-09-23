[%%shared.start]

val navigation_bar : unit -> [> `Ul ] Eliom_content.Html.F.elt Lwt.t

val os_header :
  ?user:Os_user.t ->
  unit -> [> Html_types.nav ] Eliom_content.Html.F.elt Lwt.t

val os_footer : unit -> [> `Footer ] Eliom_content.Html.F.elt

val connected_welcome_box :
  unit -> [> Html_types.div ] Eliom_content.Html.F.elt Lwt.t

val get_user_data : Os_user.id option -> Os_user.t option Lwt.t

val page :
  Os_user.id option ->
  [< Html_types.div_content_fun > `Div ] Eliom_content.Html.F.elt
  Eliom_content.Html.F.list_wrap ->
  [> `Div | `Footer | `Nav ] Eliom_content.Html.F.elt list Lwt.t

[%%server.start]

val get_wrong_pdata :
  unit -> ((string * string) * (string * string)) option Lwt.t

[%%client.start]

val get_wrong_pdata :
  (Deriving_Json.Json_unit.a, ((string * string) * (string * string)) option)
  Eliom_client.server_function
