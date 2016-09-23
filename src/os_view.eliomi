(* Ocsigen-start

 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright (C) Université Paris Diderot, CNRS, INRIA, Be Sport.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

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
