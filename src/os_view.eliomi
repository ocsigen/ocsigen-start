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

[%%client.start]

(** [check_password_confirmation ~password ~confirmation] adds a listener to
    the element [confirmation] which checks if the value of [password] and
    [confirmation] match.
 *)
val check_password_confirmation :
  password:[< Html_types.input] Eliom_content.Html.elt ->
  confirmation:[< Html_types.input] Eliom_content.Html.elt ->
  unit

[%%shared.start]

(** This module defines functions to create password forms, connection forms,
    settings buttons and other common contents arising in applications.
    As Eliom_content.Html.F is opened by default, if the module D is not
    explicitly used, HTML tags will be functional.
 *)

(** [generic_email_form ~a ~label ~text ~service ()] creates an email POST form
    with an input of type email and a submit button.

    @param a modify the attributes of the form.
    @param label add a label (none by default) to the email input.
    @param text text for the button ["Send" by default].
    @param service service which the data is sent to. *)
val generic_email_form :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.D.attrib list ->
  ?label:string Eliom_content.Html.F.wrap ->
  ?text:string ->
  ?email:string ->
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

(** [connect_form ()] creates a POST login form with email, password, a
    checkbox to stay logged in and a submit button with default placeholders.
    The data is sent to {!Os_services.connect_service}.

    @param a attributes of the form. *)
val connect_form :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.D.attrib list ->
  ?email:string ->
  unit ->
  [> Html_types.form ] Eliom_content.Html.D.elt

(** [disconnect_button ~a ()] creates a disconnect POST form with a button
    without value, a signout icon and a text message "logout".

    @param a attributes of the form. *)
val disconnect_button :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.F.attrib list ->
  unit ->
  [> Html_types.form ] Eliom_content.Html.F.elt

(** [sign_up_form ~a ()] creates a {!generic_email_form} with the service
    {!Os_services.sign_up_service}.

    @param a  attributes of the form. *)
val sign_up_form :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.D.attrib list ->
  ?email:string ->
  unit ->
  [> Html_types.form ] Eliom_content.Html.D.elt

(** [forgot_password_form ~a ()] creates a {!generic_email_form} with the
    service {!Os_services.forgot_password_service}.

    @param a attributes of the form. *)
val forgot_password_form :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.D.attrib list ->
  unit ->
  [> Html_types.form ] Eliom_content.Html.D.elt

(** [information_form ~a ~firstname ~lastname ~password1 ~password2 ()] creates
    a POST form to update the user information like first name, last name and
    password.
    It also checks (client-side) if the passwords match when the send button is
    pressed and a custom validity message is showed if they don't match.
    The data is sent to {!Os_services.set_personal_data_service}.

    @param a attributes of the form.
    @param firstname the default value for the first name.
    @param lastname the default value for the last name.
    @param password1 the default value for the password1.
    @param password2 the default value for the password2 (ie the confirmation
    password). *)
val information_form :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.D.attrib list ->
  ?firstname:string ->
  ?lastname:string ->
  ?password1:string ->
  ?password2:string ->
  unit ->
  [> Html_types.form ] Eliom_content.Html.D.elt

(** [preregister_form ~a label] creates a {!generic_email_form} with the service
    {!Os_services.preregister_service} and add the label [label] to the email
    input form.

    @param a attributes of the form.
    @param label label for the email input. *)
val preregister_form :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.D.attrib list ->
  string Eliom_content.Html.F.wrap ->
  [> Html_types.form ] Eliom_content.Html.D.elt

(** [home_button ~a ()] creates a input button with value "home" which redirects
    to the main service.

    @param a attributes of the form. *)
val home_button :
  ?a:[< Html_types.form_attrib ] Eliom_content.Html.F.attrib list ->
  unit ->
  [> Html_types.form ] Eliom_content.Html.F.elt

(** [avatar user] creates an image HTML tag (with Eliom_content.HTML.F) with an
    alt attribute to "picture" and with class "os_avatar". If the user has no
    avatar, the default icon representing the user (see <<a_api
    project="ocsigen-toolkit" | val Os_icons.F.user >>) is returned.

    @param user the user. *)
val avatar :
  Os_types.User.t ->
  [> `I | `Img ] Eliom_content.Html.F.elt

(** [username user] creates a div with class "os_username" containing:
    - [firstname] [lastname] if the user has a firstname.
    - User [userid] else.

    FIXME/IMPROVEME: use an option for the case the user has no firstname?
    Firstname must be empty because it must be optional.

    @param user the user. *)
val username :
  Os_types.User.t ->
  [> Html_types.div ] Eliom_content.Html.F.elt

(** [password_form ~a ~service ()] defines a POST form with two inputs for a
    password form (password and password confirmation) and a send button.
    It also checks (client-side) if the passwords match when the send button is
    pressed.

    @param a modify the attributes of the form.
    @param service service which the data is sent to. *)
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
