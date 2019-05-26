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

(** This module provides functions and types about users. *)

[%%shared.start]

(** Type alias to {!Os_types.User.id} to allow to use [Os_user.id]. *)
type id = Os_types.User.id [@@deriving json]

(** Type alias to {!Os_types.User.t} to allow to use [Os_user.t]. *)
type t = Os_types.User.t = {
    userid : id;
    fn : string;
    ln : string;
    avatar : string option;
    language : string option;
  } [@@deriving json]

[%%server.start]

(** Exception used if an user already exists. The parameter is the userid of the
    existing user.
 *)
exception Already_exists of Os_types.User.id

(** Exception used if an user doesn't exist. *)
exception No_such_user

(** [password_set userid] returns [true] if the user with ID [userid] has set
    a password. Else [false].
 *)
val password_set : Os_types.User.id -> bool Lwt.t

(** Reference used to remember if a wrong password has been already typed. *)
val wrong_password : bool Eliom_reference.Volatile.eref

(** Reference used to remember if the account is activated. *)
val account_not_activated : bool Eliom_reference.Volatile.eref

(** Reference used to remember if the user already exists. *)
val user_already_exists : bool Eliom_reference.Volatile.eref

(** Reference used to remember if the user exists. *)
val user_does_not_exist : bool Eliom_reference.Volatile.eref

(** Reference used to remember if the user is already preregistered. *)
val user_already_preregistered : bool Eliom_reference.Volatile.eref

(** Reference used to remember if an action link key is outdated. *)
val action_link_key_outdated : bool Eliom_reference.Volatile.eref

[%%shared.start]

(** [userid_of_user user] returns the userid of the user [user]. *)
val userid_of_user : Os_types.User.t -> Os_types.User.id

(** [firstname_of_user user] returns the first name of the user [user] *)
val firstname_of_user : Os_types.User.t -> string

(** [lastname_of_user user] returns the last name of the user [user] *)
val lastname_of_user : Os_types.User.t -> string

(** [avatar_of_user user] returns the avatar of the user [user] as [Some
    avatar_uri]. It returns [None] if the user [user] has no avatar.
 *)
val avatar_of_user : Os_types.User.t -> string option

(** [avatar_uri_of_avatar ?absolute_path avatar] returns the URI (absolute or
    relative) depending on the value of [absolute_path]) of the avatar
    [avatar].
 *)
val avatar_uri_of_avatar :
  ?absolute_path:bool -> string -> Eliom_content.Xml.uri

(** [avatar_uri_of_user user] returns the avatar URI (absolute or relative)
    depending on the value of [absolute_path]) of the avatar of the user [user].
    It returns [None] is the user [user] has no avatar.
 *)
val avatar_uri_of_user :
  ?absolute_path:bool -> Os_types.User.t -> Eliom_content.Xml.uri option

(** [language_of_user user] returns the language of the user [user] *)
val language_of_user : Os_types.User.t -> string option

(** Retrieve the full name of user (which is the concatenation of the first name
    and last name).
 *)
val fullname_of_user : Os_types.User.t -> string

(** [is_complete user] returns [true] if the first name and the last name of
    {!Os_types.user} have been completed yet.
 *)
val is_complete : Os_types.User.t -> bool

[%%server.start]

(** [emails_of_user user] returns the emails of the user [user]. *)
val emails_of_user : Os_types.User.t -> string Lwt.t

(** [add_actionlinkkey ?autoconnect ?action ?data ?validity ~act_key ~userid
    ~email ()] adds the action key in the database.
 *)
(* Use {!Os_types.actionlinkkey_info} instead of each parameter? *)
val add_actionlinkkey :
  (* by default, an action_link key is just an activation key *)
  ?autoconnect:bool -> (** default: false *)
  ?action:[ `AccountActivation | `PasswordReset | `Custom of string ] ->
  (** default: `AccountActivation *)
  ?data:string -> (** default: empty string *)
  ?validity:int64 -> (** default: 1L *)
  act_key:string -> userid:Os_types.User.id -> email:string -> unit -> unit Lwt.t

(** [verify_password email password] verifies if [email] and [password]
    correspond. It it is the case, it returns the userid of the user with email
    [email]. Else, it raises the exception {!Os_db.No_such_resource}.
 *)
val verify_password : email:string -> password:string -> Os_types.User.id Lwt.t

(** [user_of_userid userid] returns the information about the user with ID
    [userid].
 *)
val user_of_userid : Os_types.User.id -> Os_types.User.t Lwt.t

(** Retrieve the data corresponding to an action link key, each
    call decrements the validity of the key by [1] if it exists and
    [validity > 0] (it remains at [0] if it's already [0]). It is up to
    you to adapt the actions according to the value of validity!
    Raises {!Os_db.No_such_resource} if the action link key is not found.
 *)
val get_actionlinkkey_info : string -> Os_types.Action_link_key.info Lwt.t

(** [userid_of_email email] returns the userid of the user with email [email].
    It raises the exception {!Os_db.No_such_resource} if the email [email] is
    not used.
 *)
val userid_of_email : string -> Os_types.User.id Lwt.t

(** [emails_of_userid userid] returns the emails list of user with ID
    [userid].
 *)
val emails_of_userid : Os_types.User.id -> string list Lwt.t

(** [email_of_userid userid] returns the main email of user with ID
    [userid].
 *)
val email_of_userid : Os_types.User.id -> string option Lwt.t

(** [emails_of_user user] returns the emails list of user [user]. *)
val emails_of_user : Os_types.User.t -> string list Lwt.t

(** [email_of_user user] returns the main email of user [user]. *)
val email_of_user : Os_types.User.t -> string option Lwt.t

(** [get_language userid] returns the language of the user with ID [userid]. The
    language is retrieved from the database.
 *)
val get_language : Os_types.User.id -> string option Lwt.t

(** [get_users ?pattern ()] gets users who match the [pattern] (useful for
    completion).
 *)
val get_users : ?pattern:string -> unit -> Os_types.User.t list Lwt.t

(** [create ?password ?avatar ?language ~firstname ~lastname email] creates a new user
    with the given information. An email, the first name and the last name are mandatory.
 *)
val create :
  ?password:string -> ?avatar:string -> ?language:string -> ?email:string ->
  firstname:string -> lastname:string -> unit -> Os_types.User.t Lwt.t

(** [update ?password ?avatar ?language ~firstname ~lastname userid] update the
    given information of the user with ID [userid]. Only given information are
    updated.
 *)
val update :
  ?password:string -> ?avatar:string -> ?language:string ->
  firstname:string -> lastname:string -> Os_types.User.id -> unit Lwt.t

(** Another version of [update] using a type {!Os_types.User.t} instead of
    label.
 *)
val update' : ?password:string -> Os_types.User.t -> unit Lwt.t

(** [update_password ~userid ~password] updates the password only. [password]
    must not be hashed: it is done by the function [f_crypt] of the tuple
    {!Os_db.pwd_crypt_ref}.
 *)
val update_password : userid:Os_types.User.id -> password:string -> unit Lwt.t

(** [update_avatar ~userid ~avatar] updates the avatar of the user with ID
    [userid].
 *)
val update_avatar : userid:Os_types.User.id -> avatar:string -> unit Lwt.t

(** [update_language ~userid ~language] updates the language of the user with ID
    [userid].
 *)
val update_language : userid:Os_types.User.id -> language:string -> unit Lwt.t

(** [is_registered email] returns [true] if a user exists with email [email].
    Else, it returns [false].
 *)
val is_registered : string -> bool Lwt.t

(** [is_preregistered email] returns [true] if a user exists with email
    [email]. Else, it returns [false].
 *)
val is_preregistered : string -> bool Lwt.t

(** [add_preregister email] adds an email into the preregister collections. *)
val add_preregister : string -> unit Lwt.t

(** [remove_preregister email] removes an email from the preregister
    collections.
 *)
val remove_preregister : string -> unit Lwt.t

(** Get [limit] (default: 10) emails from the preregister collections. *)
val all : ?limit:int64 -> unit -> string list Lwt.t

(** By default, passwords are encrypted using Bcrypt.
    You can customize this by calling this function
    with a pair of function (crypt and check password).
    The first parameter of the second function is the user id
    (in case you need it).
    Then it takes as second parameter the password given
    by user, and as third parameter the hash found in database.
*)
val set_pwd_crypt_fun : (string -> string) *
                        (Os_types.User.id -> string -> string -> bool) -> unit

(** [remove_email_from_user ~userid ~email] removes the email [email] from the
    user with the id [userid]. If the email is registered as the main email for
    the user it fails with the exception {!Os_db.Main_email_removal_attempt}.
*)
val remove_email_from_user : userid:Os_types.User.id -> email:string -> unit Lwt.t

(** [is_email_validated ~userid ~email] returns whether for a user designated by
    its id the given email has been validated.
 *)
val is_email_validated : userid:Os_types.User.id -> email:string -> bool Lwt.t

(** [is_main_email ~userid ~email] returns whether an email is the main email
    registered for a given user designated by its id.
 *)
val is_main_email : userid:Os_types.User.id -> email:string -> bool Lwt.t

(** [update_mail_email ~userid ~email] sets the main email for a user with the
    ID [userid] as the email [email].
 *)
val update_main_email : userid:Os_types.User.id -> email:string -> unit Lwt.t
