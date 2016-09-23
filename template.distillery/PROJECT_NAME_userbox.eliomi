(* WARNING generated in an ad-hoc fashion. Use with care! *)
[%%shared.start]

val connected_user_box :
  Os_user.t -> [> Html_types.div ] Eliom_content.Html.D.elt

val connection_box :
  unit -> [> Html_types.div ] Eliom_content.Html.D.elt Lwt.t

val msg :
  unit -> [> Html_types.div ] Eliom_content.Html.D.elt

val userbox :
  Os_user.t option -> [> Html_types.div ] Eliom_content.Html.F.elt Lwt.t
