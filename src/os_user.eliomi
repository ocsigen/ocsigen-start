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

(** Type alias to {!Os_types.userid} to allow to use [Os_user.id]. *)
type id = Os_types.userid [@@deriving json]

(** Type alias to {!Os_types.user} to allow to use [Os_user.t]. *)
type t = Os_types.user = {
    userid : id;
    fn : string;
    ln : string;
    avatar : string option;
  } [@@deriving json]

[%%server.start]
exception Already_exists of Os_types.userid
exception No_such_user

(** Has user set its password? *)
val password_set : Os_types.userid -> bool Lwt.t

[%%shared.start]

(** The type which represents a user. *)

val userid_of_user : Os_types.user -> Os_types.userid
val firstname_of_user : Os_types.user -> string
val lastname_of_user : Os_types.user -> string
val avatar_of_user : Os_types.user -> string option
val avatar_uri_of_avatar :
  ?absolute_path:bool -> string -> Eliom_content.Xml.uri
val avatar_uri_of_user :
  ?absolute_path:bool -> Os_types.user -> Eliom_content.Xml.uri option

(** Retrieve the full name of user. *)
val fullname_of_user : Os_types.user -> string

(** Returns true if the firstname and the lastname of [Os_types.user] has not
  * been completed yet. *)
val is_complete : Os_types.user -> bool

[%%server.start]

val emails_of_user : Os_types.user -> string Lwt.t

val add_actionlinkkey :
  (* by default, an action_link key is just an activation key *)
  ?autoconnect:bool -> (** default: false *)
  ?action:[ `AccountActivation | `PasswordReset | `Custom of string ] ->
  (** default: `AccountActivation *)
  ?data:string -> (** default: empty string *)
  ?validity:int64 -> (** default: 1L *)
  act_key:string -> userid:Os_types.userid -> email:string -> unit -> unit Lwt.t

val verify_password : email:string -> password:string -> Os_types.userid Lwt.t

(** returns user information.
    Results are cached in memory during page generation. *)
val user_of_userid : Os_types.userid -> Os_types.user Lwt.t

val get_actionlinkkey_info : string -> Os_types.actionlinkkey_info Lwt.t
(** Retrieve the data corresponding to an action link key, each
    call decrements the validity of the key by 1 if it exists and
    validity > 0 (it remains at 0 if it's already 0). It is up to
    you to adapt the actions according to the value of validity!
    Raises [Os_db.No_such_resource] if the action link key is not found. *)

val userid_of_email : string -> Os_types.userid Lwt.t

(** Retrieve e-mails from user id. *)
val emails_of_userid : Os_types.userid -> string list Lwt.t

(** Retrieve the main e-mail of a user. *)
val email_of_user : Os_types.user -> string Lwt.t

(** Retrieve the main e-mail from user id. *)
val email_of_userid : Os_types.userid -> string Lwt.t

(** Retrieve e-mails of a user. *)
val emails_of_user : Os_types.user -> string list Lwt.t

(** Get users who match the [pattern] (useful for completion) *)
val get_users : ?pattern:string -> unit -> Os_types.user list Lwt.t

(** Create a new user *)
val create :
  ?password:string -> ?avatar:string ->
  firstname:string -> lastname:string -> string -> Os_types.user Lwt.t

(** Update the informations of a user. *)
val update :
  ?password:string -> ?avatar:string ->
  firstname:string -> lastname:string -> Os_types.userid -> unit Lwt.t

(** Another version of [update] using a type [Os_types.user] instead of
    label. *)
val update' : ?password:string -> Os_types.user -> unit Lwt.t

(** Update the password only *)
val update_password : userid:Os_types.userid -> password:string -> unit Lwt.t

(** Update the avatar only *)
val update_avatar : userid:Os_types.userid -> avatar:string -> unit Lwt.t

(** Check wether or not a user exists *)
val is_registered : string -> bool Lwt.t

(** Check wether or not a user exists. *)
val is_preregistered : string -> bool Lwt.t

(** Add an email into the preregister collections. *)
val add_preregister : string -> unit Lwt.t

(** Rempve an email from the preregister collections. *)
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
                        (Os_types.userid -> string -> string -> bool) -> unit

(** Removes the email [email] from the user with the id [userid],
    if the email is registered as the main email for the user it fails
    with the exception [Main_email_removal_attempt].
*)
val remove_email_from_user : userid:Os_types.userid -> email:string -> unit Lwt.t

(** Returns whether for a user designated by its id the given email has been
    validated. *)
val is_email_validated : userid:Os_types.userid -> email:string -> bool Lwt.t

(** Returns whether an email is the  main email registered for a
    given user designated by its id. *)
val is_main_email : userid:Os_types.userid -> email:string -> bool Lwt.t

(** Sets the main email for a user with the id [userid] as the email [email]. *)
val update_main_email : userid:Os_types.userid -> email:string -> unit Lwt.t
