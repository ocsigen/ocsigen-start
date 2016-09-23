[%%shared.start]

val css_name : string

val css_name_script : [> Html_types.script ] Eliom_content.Html.F.elt list

val app_js : [> `Script ] Eliom_content.Html.elt list

val the_local_js : 'a list

val the_local_css : string list list

module Page_config :
  sig
    val js : string list list

    val css : string list list

    val default_error_page_full :
      ('a -> 'b -> exn -> Os_page.content Lwt.t) option

    val default_connected_error_page_full :
      (Os_user.id option -> 'a -> 'b -> exn -> Os_page.content Lwt.t) option

    val title : string

    val local_js : 'a list

    val local_css : string list list

    val other_head : [> Html_types.script ] Eliom_content.Html.F.elt list

    val default_predicate : 'a -> 'b -> bool Lwt.t

    val default_connected_predicate : 'a -> 'b -> 'c -> bool Lwt.t

    val default_error_page :
      'a ->
      'b ->
      exn -> [> `Div | `Footer | `Nav ] Eliom_content.Html.F.elt list Lwt.t
    val default_connected_error_page :
      Os_user.id option ->
      'a ->
      'b ->
      exn -> [> `Div | `Footer | `Nav ] Eliom_content.Html.F.elt list Lwt.t
  end

val make_page :
  [< Html_types.body_content ] Eliom_content.Html.elt list ->
  [> Html_types.html ] Eliom_content.Html.elt

val page :
  ?predicate:('a -> 'b -> bool Lwt.t) ->
  ?fallback:('a ->
             'b ->
             exn -> Html_types.body_content Eliom_content.Html.elt list Lwt.t) ->
  ('a -> 'b -> Html_types.body_content Eliom_content.Html.elt list Lwt.t) ->
  'a -> 'b -> Html_types.html Eliom_content.Html.elt Lwt.t

module Opt :
  sig
    val connected_page :
      ?allow:Os_group.t list ->
      ?deny:Os_group.t list ->
      ?predicate:(Os_user.id option -> 'a -> 'b -> bool Lwt.t) ->
      ?fallback:
      (
        Os_user.id option ->
        'a ->
        'b ->
        exn ->
        Html_types.body_content Eliom_content.Html.elt list Lwt.t
      ) ->
      (
        Os_user.id option ->
        'a ->
        'b ->
        Html_types.body_content Eliom_content.Html.elt list Lwt.t
      ) ->
      'a ->
      'b ->
      Html_types.html Eliom_content.Html.elt Lwt.t

    val connected_page_full :
      ?allow:Os_group.t list ->
      ?deny:Os_group.t list ->
      ?predicate:(Os_user.id option -> 'a -> 'b -> bool Lwt.t) ->
      ?fallback:(Os_user.id option ->
                 'a -> 'b -> exn -> Os_page.content Lwt.t) ->
      (Os_user.id option -> 'a -> 'b -> Os_page.content Lwt.t) ->
      'a -> 'b -> Html_types.html Eliom_content.Html.elt Lwt.t
  end

val connected_page :
  ?allow:Os_group.t list ->
  ?deny:Os_group.t list ->
  ?predicate:(Os_user.id option -> 'a -> 'b -> bool Lwt.t) ->
  ?fallback:(Os_user.id option ->
             'a ->
             'b ->
             exn -> Html_types.body_content Eliom_content.Html.elt list Lwt.t) ->
  (Os_user.id ->
   'a -> 'b -> Html_types.body_content Eliom_content.Html.elt list Lwt.t) ->
  'a -> 'b -> Html_types.html Eliom_content.Html.elt Lwt.t

val connected_page_full :
  ?allow:Os_group.t list ->
  ?deny:Os_group.t list ->
  ?predicate:(Os_user.id option -> 'a -> 'b -> bool Lwt.t) ->
  ?fallback:(Os_user.id option -> 'a -> 'b -> exn -> Os_page.content Lwt.t) ->
  (Os_user.id -> 'a -> 'b -> Os_page.content Lwt.t) ->
  'a -> 'b -> Html_types.html Eliom_content.Html.elt Lwt.t
