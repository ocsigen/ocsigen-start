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

(** This module contains pre-defined handlers for connect, disconnect, sign up,
    add a new email, etc. Each handler has a corresponding service in
    {!Os_services}.
 *)

(** [connect_handler () ((login, password), keepMeLoggedIn)] connects the user
    with [login] and [password] and keeps the user logged in between different
    session if [keepMeLoggedIn] is set to [true]. *)
val connect_handler : unit -> (string * string) * bool -> unit Lwt.t

(** [disconnect_handler ?main_page () ()] disconnects the current user. *)
val disconnect_handler : ?main_page:bool -> unit -> unit -> unit Lwt.t

(** [sign_up_handler () email] signes up an user with email [email]. *)
val sign_up_handler : unit -> string -> unit Lwt.t

(** [add_email_handler () email] adds a new e-mail address
    for the current user and sends an activation link. *)
val add_email_handler : unit -> string -> unit Lwt.t

(** Exception raised when something went wrong with an action link key. The
    action link key is given as parameter as a type
    {!Os_types.actionlinkkey_info}.
 *)
exception Custom_action_link of
    Os_types.Action_link_key.info
    * bool (* If true, the link corresponds to a phantom user
              (user who never created its account).
              In that case, you probably want to display a sign-up form,
              and in the other case a login form. *)

(** Exception raised when an account has been already activated and no user is
    connected.
 *)
exception Account_already_activated_unconnected of Os_types.Action_link_key.info

(** Exception raised when the key is oudated. *)
exception Invalid_action_key of Os_types.Action_link_key.info

(** Exception raised when the requested resource is not available. *)
exception No_such_resource

[%%shared.start]

(** [action_link_handler userid_o activation_key ()] is the handler for
    activation keys.

    Depending on the error, {!No_such_resource}, {!Custom_action_link},
    {!Invalid_action_key} or {!Account_already_activated_unconnected} can be
    raised.
 *)
val action_link_handler :
  int64 option ->
  string ->
  unit ->
  'a Eliom_registration.application_content Eliom_registration.kind Lwt.t

[%%server.start]

(** [forgot_password_handler service () email] creates and sends an action link
    to [email] if the user forgot his password and redirects to [service].
    If [email] doesn't correspond to any user, {!Os_user.user_does_not_exist}
    is set to [true] and {!Os_msg.msg} is called with the level [`Err].
 *)
val forgot_password_handler :
  (unit, unit, Eliom_service.get, Eliom_service.att, _,
   Eliom_service.non_ext, _, _, unit, unit, 'c)
    Eliom_service.t ->
  unit -> string -> unit Lwt.t

(** [preregister_handler () email] preregisters the email [email]. *)
val preregister_handler :
  unit -> string -> unit Lwt.t

(** [set_password_handler userid () (password, confirmation_password)] updates
    the password of the user with ID [userid] with the hashed value of
    [password] if [confirmation_password] corresponds to [password]. If they
    don't correspond, {!Os_msg.msg} is called with the level [`Err].
 *)
val set_password_handler :
  Os_types.User.id -> unit -> string * string -> unit Lwt.t

(** [set_personal_data_handler userid () ((firstname, lastname), (password,
    confirmation_password))] sets the corresponding data to given values.
 *)
val set_personal_data_handler :
  Os_types.User.id -> unit -> (string * string) * (string * string) -> unit Lwt.t

[%%client.start]

(** [set_password_rpc (password, confirmation_password)] is a RPC to
    [set_password].
 *)
val set_password_rpc : string * string -> unit Lwt.t

(** [restart ?url ()] restarts the client and redirects to the url [url]. *)
val restart : ?url:string -> unit -> unit
