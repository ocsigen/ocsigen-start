[%%shared.start]

module Navigation_bar :
  sig
    val ul_of_elts :
      ?ul_class:string list ->
      (
        string *
        (
          unit,
          unit,
          Eliom_service.get,
          'a,
          'b,
          'c,
          'd,
          [< `WithSuffix | `WithoutSuffix ],
          'e,
          unit,
          Eliom_service.non_ocaml
        ) Eliom_service.t
      ) list ->
      [> `Ul ] Eliom_content.Html.F.elt Lwt.t
  end

val popup_button :
  button_name:string Eliom_content.Html.D.wrap ->
  ?button_class:Html_types.nmtokens Eliom_content.Html.D.wrap ->
  popup_content:(unit -> [< Html_types.div_content ] Eliom_content.Html.elt Lwt.t) ->
  [> Html_types.button ] Eliom_content.Html.D.elt Lwt.t

module Carousel :
  sig
    val make :
      ?vertical:bool ->
      update:[ `Goto of int | `Next | `Prev ] React.event
             Eliom_client_value.t ->
      change:([ `Goto of int | `Next | `Prev ] -> unit) Eliom_client_value.t ->
      carousel:[< Html_types.div_attrib ] Eliom_content.Html.attrib list *
               [< Html_types.div_content ] Eliom_content.Html.elt list ->
      ?ribbon:[< Html_types.ul_attrib ] Eliom_content.Html.attrib list *
              [< Html_types.li_content_fun ] Eliom_content.Html.elt list list ->
      ?previous:[< Html_types.button_attrib ] Eliom_content.Html.attrib list *
                Html_types.button_content Eliom_content.Html.elt list ->
      ?next:[< Html_types.button_attrib ] Eliom_content.Html.attrib list *
            Html_types.button_content Eliom_content.Html.elt list ->
      ?bullets:[< Html_types.ul_attrib ] Eliom_content.Html.attrib list *
               [< Html_types.li_content_fun ] Eliom_content.Html.elt list
               list ->
      unit ->
      [> Html_types.div ] Eliom_content.Html.elt *
      [> Html_types.div ] Eliom_content.Html.elt option *
      [> Html_types.button ] Eliom_content.Html.elt option *
      [> Html_types.button ] Eliom_content.Html.elt option *
      [> Html_types.ul ] Eliom_content.Html.elt option
  end
