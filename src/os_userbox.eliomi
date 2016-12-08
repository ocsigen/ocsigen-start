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

(** Connexion box, box with connected user information and menu *)

[%%shared.start]

type uploader = (unit,unit) Ot_picture_uploader.service

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
val upload_pic_link :
  ?a:[< Html_types.a_attrib > `OnClick ] Eliom_content.Html.D.Raw.attrib list
  -> ?content:Html_types.a_content Eliom_content.Html.D.Raw.elt list
  -> ?error_while_uploading_msg:string
  -> ?crop:float option
  -> ?input:
    Html_types.label_attrib Eliom_content.Html.D.Raw.attrib list
     * Html_types.label_content_fun Eliom_content.Html.D.Raw.elt list
  -> ?submit:
    Html_types.button_attrib Eliom_content.Html.D.Raw.attrib list
     * Html_types.button_content_fun Eliom_content.Html.D.Raw.elt list
  -> (unit -> unit) Eliom_client_value.t
  -> uploader
  -> Os_types.User.id
  -> [> `A of Html_types.a_content ] Eliom_content.Html.D.Raw.elt

(** Link to start to see the help from the beginning.
    The client function given as first parameter will be called first,
    for example to close the menu containing the link.
    [?text_link] corresponds to the link text (default is
    {!Os_i18n.Current.see_help_again_from_beginning}).
 *)
val reset_tips_link :
  ?text_link:string                   ->
  (unit -> unit) Eliom_client_value.t ->
  [> `A of [> `PCDATA ] ] Eliom_content.Html.D.Raw.elt

[%%server.start]

(** Reference used to remember if a wrong password has been already typed. *)
val wrong_password : bool Eliom_reference.Volatile.eref

(** Reference used to remember if the account is activated. *)
val account_not_activated : bool Eliom_reference.Volatile.eref

(** Reference used to remember if the user already exists. *)
val user_already_exists : bool Eliom_reference.Volatile.eref

(** Reference used to remember if the user exists. *)
val user_does_not_exist : bool Eliom_reference.Volatile.eref

(** Reference used to remeber if the user is already preregistered. *)
val user_already_preregistered : bool Eliom_reference.Volatile.eref

(** Reference used to remeber if an action link key is outdated. *)
val action_link_key_outdated : bool Eliom_reference.Volatile.eref
