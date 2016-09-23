[%%shared.start]
val generic_email_form :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.D.attrib list ->
  ?label:string Eliom_content.Html.F.wrap ->
  ?text:string ->
  service:(
    unit,
    'a,
    Eliom_service.post,
    'b,
    'c,
    'd,
    'e,
    [< `WithSuffix | `WithoutSuffix ],
    'f,
    [< string Eliom_parameter.setoneradio ]
    Eliom_parameter.param_name,
    Eliom_service.non_ocaml
  ) Eliom_service.t ->
  unit ->
  [> Html_types.form ] Eliom_content.Html.D.elt

val connect_form :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.D.attrib list ->
  unit ->
  [> Html_types.form ] Eliom_content.Html.D.elt

val disconnect_button :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.F.attrib list ->
  unit ->
  [> Html_types.form ] Eliom_content.Html.F.elt

val sign_up_form :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.D.attrib list ->
  unit ->
  [> Html_types.form ] Eliom_content.Html.D.elt

val forgot_password_form :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.D.attrib list ->
  unit ->
  [> Html_types.form ] Eliom_content.Html.D.elt

val information_form :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.D.attrib list ->
  ?firstname:string ->
  ?lastname:string ->
  ?password1:string ->
  ?password2:string ->
  unit ->
  [> Html_types.form ] Eliom_content.Html.D.elt

val preregister_form :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.D.attrib list ->
  string Eliom_content.Html.F.wrap ->
  [> Html_types.form ] Eliom_content.Html.D.elt

val home_button :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.F.attrib list ->
  unit ->
  [> Html_types.form ] Eliom_content.Html.F.elt

val avatar :
  Os_user.t ->
  [> `I | `Img ] Eliom_content.Html.F.elt

val username :
  Os_user.t ->
  [> Html_types.div ] Eliom_content.Html.F.elt

val password_form :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.D.attrib list ->
  service:(
    unit,
    'a,
    Eliom_service.post,
    'b,
    'c,
    'd,
    'e,
    [< `WithSuffix | `WithoutSuffix ],
    'f,
    [< string Eliom_parameter.setoneradio ] Eliom_parameter.param_name *
      [< string Eliom_parameter.setoneradio ] Eliom_parameter.param_name,
    Eliom_service.non_ocaml
  ) Eliom_service.t ->
  unit ->
  [> Html_types.form ] Eliom_content.Html.D.elt
