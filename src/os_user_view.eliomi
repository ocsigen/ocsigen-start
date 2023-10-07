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

(** This module defines functions to create password forms, connection forms,
    settings buttons and other common contents arising in applications.
    As Eliom_content.Html.F is opened by default, if the module D is not
    explicitly used, HTML tags will be functional.
 *)

[%%client.start]

val check_password_confirmation :
   password:[< Html_types.input] Eliom_content.Html.elt
  -> confirmation:[< Html_types.input] Eliom_content.Html.elt
  -> unit
(** [check_password_confirmation ~password ~confirmation] adds a listener to
    the element [confirmation] which checks if the value of [password] and
    [confirmation] match.
 *)

[%%shared.start]

val generic_email_form :
   ?a:[< Html_types.form_attrib] Eliom_content.Html.D.attrib list
  -> ?label:string Eliom_content.Html.F.wrap
  -> ?a_placeholder_email:string
  -> ?text:string
  -> ?email:string
  -> service:
       ( unit
         , 'a
         , Eliom_service.post
         , 'b
         , 'c
         , 'd
         , 'e
         , [< `WithSuffix | `WithoutSuffix]
         , 'f
         , [< string Eliom_parameter.setoneradio] Eliom_parameter.param_name
         , Eliom_service.non_ocaml )
         Eliom_service.t
  -> unit
  -> [> Html_types.form] Eliom_content.Html.D.elt
(** [generic_email_form ?a ?label ?text ?email ~service ()] creates an email
    POST form with an input of type email and a submit button. Placeholder value
    ["e-mail address"] is used for the email input.

    @param a add attributes of the form.
    @param label add a label (default is [None]) to the email input.
    @param text text for the button (default is ["Send"]).
    @param email the default value of the email input (default is empty).
    @param service service which the data is sent to.
 *)

val connect_form :
   ?a_placeholder_email:string
  -> ?a_placeholder_phone:string
  -> ?a_placeholder_pwd:string
  -> ?text_keep_me_logged_in:string
  -> ?text_sign_in:string
  -> ?a:[< Html_types.form_attrib] Eliom_content.Html.D.attrib list
  -> ?email:string
  -> unit
  -> [> Html_types.form] Eliom_content.Html.D.elt
(** [connect_form ?a ?email ()] creates a POST login form with email, password,
    a checkbox to stay logged in (with default text to ["keep me logged in"] in
    a span) and a submit button. Default placeholders for input email (resp.
    password) is ["Your email"] (resp. ["Your password"]).

    The data is sent to {!Os_services.connect_service}.

    @param a_placeholder_email text for the placeholder of the email input.
    @param a_placeholder_pwd text for the placeholder of the password input.
    @param text_keep_me_logged_in text for the check box to stay connected.
    @param text_sign_in text for the sign in button.
    @param a attributes of the form.
    @param email the default value of the email input (default is empty).
 *)

val disconnect_button :
   ?a:[< Html_types.form_attrib] Eliom_content.Html.F.attrib list
  -> ?text_logout:string
  -> unit
  -> [> Html_types.form] Eliom_content.Html.F.elt
(** [disconnect_button ?a ()] creates a disconnect POST form with a button
    without value, a signout icon and a text message ["logout"].

    @param a attributes of the form. *)

val sign_up_form :
   ?a:[< Html_types.form_attrib] Eliom_content.Html.D.attrib list
  -> ?a_placeholder_email:string
  -> ?text:string
  -> ?email:string
  -> unit
  -> [> Html_types.form] Eliom_content.Html.D.elt
(** [sign_up_form ?a ?email ()] creates a {!generic_email_form} with the service
    {!Os_services.sign_up_service}.

    @param a attributes of the form.
    @param email the default value of the email input (default is empty).
 *)

val forgot_password_form :
   ?a:[< Html_types.form_attrib] Eliom_content.Html.D.attrib list
  -> unit
  -> [> Html_types.form] Eliom_content.Html.D.elt
(** [forgot_password_form ~a ()] creates a {!generic_email_form} with the
    service {!Os_services.forgot_password_service}.

    @param a attributes of the form.
 *)

val information_form :
   ?a:[< Html_types.form_attrib] Eliom_content.Html.D.attrib list
  -> ?a_placeholder_password:string
  -> ?a_placeholder_retype_password:string
  -> ?a_placeholder_firstname:string
  -> ?a_placeholder_lastname:string
  -> ?text_submit:string
  -> ?firstname:string
  -> ?lastname:string
  -> ?password1:string
  -> ?password2:string
  -> unit
  -> [> Html_types.form] Eliom_content.Html.D.elt
(** [information_form ~a ~firstname ~lastname ~password1 ~password2 ()] creates
    a POST form to update the user information like first name, last name and
    password.
    It also checks (client-side) if the passwords match when the send button is
    pressed and a custom validity message is showed if they don't match.
    The data is sent to {!Os_services.set_personal_data_service}.

    @param a attributes of the form.
    @param a_placeholder_password text for the placeholder of the password input.
    @param a_placeholder_retype_password text for the placeholder of the confirmation password input.
    @param a_placeholder_firstname text for the placeholder of the firstname input.
    @param a_placeholder_lastname text for the placeholder of the lastname input.
    @param text_submit text for the submit button.
    @param firstname the default value for the first name.
    @param lastname the default value for the last name.
    @param password1 the default value for the password1.
    @param password2 the default value for the password2 (ie the confirmation
    password). *)

val preregister_form :
   ?a:[< Html_types.form_attrib > `OnSubmit] Eliom_content.Html.D.attrib list
  -> string Eliom_content.Html.F.wrap
  -> [> Html_types.form] Eliom_content.Html.D.elt
(** [preregister_form ~a label] creates a {!generic_email_form} with the service
    {!Os_services.preregister_service} and add the label [label] to the email
    input form.

    @param a attributes of the form.
    @param label label for the email input. *)

val home_button :
   ?a:[< Html_types.form_attrib] Eliom_content.Html.F.attrib list
  -> unit
  -> [> Html_types.form] Eliom_content.Html.F.elt
(** [home_button ~a ()] creates an input button with value "home" which
    redirects to the main service.

    @param a attributes of the form. *)

val avatar : Os_types.User.t -> [> `I | `Img] Eliom_content.Html.F.elt
(** [avatar user] creates an image HTML tag (with Eliom_content.HTML.F) with an
    alt attribute to ["picture"] and with class ["os-avatar"]. If the user has
    no avatar, the default icon representing the user (see <<a_api
    project="ocsigen-toolkit" | val Ot_icons.F.user >>) is returned.

    @param user the user. *)

val username : Os_types.User.t -> [> Html_types.div] Eliom_content.Html.F.elt
(** [username user] creates a div with class ["os_username"] containing:
    - [firstname] [lastname] if the user has a firstname.
    - ["User "] concatenated with the userid in other cases.

    FIXME/IMPROVEME: use an option for the case the user has no firstname?
    Firstname must be empty because it must be optional.

    @param user the user. *)

val password_form :
   ?a_placeholder_pwd:string
  -> ?a_placeholder_confirmation:string
  -> ?text_send_button:string
  -> ?a:[< Html_types.form_attrib] Eliom_content.Html.D.attrib list
  -> service:
       ( unit
         , 'a
         , Eliom_service.post
         , 'b
         , 'c
         , 'd
         , 'e
         , [< `WithSuffix | `WithoutSuffix]
         , 'f
         , [< string Eliom_parameter.setoneradio] Eliom_parameter.param_name
           * [< string Eliom_parameter.setoneradio] Eliom_parameter.param_name
         , Eliom_service.non_ocaml )
         Eliom_service.t
  -> unit
  -> [> Html_types.form] Eliom_content.Html.D.elt
(** [password_form ~a ~service ()] defines a POST form with two inputs for a
    password form (password and password confirmation) and a send button.
    It also checks (client-side) if the passwords match when the send button is
    pressed.

    @param a_placeholder_pwd placeholder test for the password input.
    @param a_placeholder_confirmation placeholder test for the confirmation input.
    @param text_send_button text for the send button.
    @param a attributes of the form.
    @param service service which the data is sent to. *)

val upload_pic_link :
   ?a:[< Html_types.a_attrib > `OnClick] Eliom_content.Html.D.Raw.attrib list
  -> ?content:Html_types.a_content Eliom_content.Html.D.Raw.elt list
  -> ?crop:float option
  -> ?input:
       Html_types.label_attrib Eliom_content.Html.D.Raw.attrib list
       * Html_types.label_content_fun Eliom_content.Html.D.Raw.elt list
  -> ?submit:
       Html_types.button_attrib Eliom_content.Html.D.Raw.attrib list
       * Html_types.button_content_fun Eliom_content.Html.D.Raw.elt list
  -> ?onclick:(unit -> unit) Eliom_client_value.t
  -> (unit, unit) Ot_picture_uploader.service
  -> [> `A of Html_types.a_content] Eliom_content.Html.D.Raw.elt
(** [upload_pic_link ?a ?content ?crop ?input ?submit action_after_submit
    service userid]

    Creates a link with a label and a submit button to upload a picture.

    The client function [action_after_submit] will be called first,
    for example to close the menu containing the link.

    You can add attributes to the HTML tag with the optional parameter [?a].
    [?input] and [?submit] are couples [(attributes, content_children)] for the
    label and the submit button where [attributes] is a list of attributes for
    the tag and [content_children] is a list of children. By default, they are
    empty.

    [?content] is the link text. The default value is "Change profile picture".

    [service] is the service called to upload the picture.

    You can crop the picture by giving a value to [?crop].
 *)

val reset_tips_link :
   ?text_link:string
  -> ?close:(unit -> unit) Eliom_client_value.t
  -> unit
  -> [> `A of [> `PCDATA]] Eliom_content.Html.D.Raw.elt
(** Link to start to see the help from the beginning.
    The client function given as first parameter will be called first,
    for example to close the menu containing the link.

    @param text_link link text.
 *)

val disconnect_all_link :
   ?text_link:string
  -> unit
  -> [> `A of [> `PCDATA]] Eliom_content.Html.D.Raw.elt
(** Link to disconnect all user sessions.

    @param text_link link text.
 *)

val disconnect_link :
   ?text_logout:string
  -> ?a:[< Html_types.a_attrib > `OnClick] Eliom_content.Html.attrib list
  -> unit
  -> [> `A of Html_types.flow5_without_interactive] Eliom_content.Html.F.elt
(** A link to {!Os_services.disconnect_service}.

    @param text_logout the link text.
    @param a attributes for the link.
 *)

val connected_user_box :
   user:Os_types.User.t
  -> [> Html_types.div] Eliom_content.Html.D.elt
(** An userbox (in a div with the CSS class ["connected-user-box"]) for connected
    users with an icon and the username.
 *)

val connection_box :
   ?a_placeholder_email:string
  -> ?a_placeholder_phone:string
  -> ?a_placeholder_pwd:string
  -> ?text_keep_me_logged_in:string
  -> ?content_popup_forgotpwd:string
  -> ?text_button_forgotpwd:string
  -> ?text_sign_in:string
  -> ?text_sign_up:string
  -> ?text_send_button:string
  -> unit
  -> [> Html_types.div] Eliom_content.Html.D.elt Lwt.t
(** A box (in a div with the CSS class ["os-connection-box"]) with a sign in and
    a sign out button. [?text_sign_in] (resp. [text_sign_up]) is the text for the
    sign in (resp. sign up) button, default is ["Sign in"] (resp. ["Sign up"]).
 *)

val user_box :
   ?a_placeholder_email:string
  -> ?a_placeholder_pwd:string
  -> ?text_keep_me_logged_in:string
  -> ?content_popup_forgotpwd:string
  -> ?text_button_forgotpwd:string
  -> ?text_sign_in:string
  -> ?text_sign_up:string
  -> ?text_send_button:string
  -> ?user:Os_types.User.t
  -> unit
  -> [> Html_types.div] Eliom_content.Html.F.elt Lwt.t
(** Return {!connection_box} if no user is connected (i.e. [user] is [None]).
    Else {!connected_user_box}.
 *)

(**/**)

val enable_phone : unit -> unit (* default : disabled *)
