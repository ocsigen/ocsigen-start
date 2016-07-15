
(*[%%shared.start]*)

val popup_button:
  button_name:string ->
  ?button_class:Html_types.nmtokens Eliom_content.Html.D.wrap ->
  'a Eliom_content.Html.elt ->
  [> Html_types.button] Eliom_content.Html.D.elt
