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
type id = int64 [@@deriving json]

[%%server.start]
exception Already_exists of id
exception No_such_user

(** Has user set its password? *)
val password_set : id -> bool Lwt.t

[%%shared.start]

(** The type which represents a user. *)
type t = {
    userid : id;
    fn : string;
    ln : string;
    avatar : string option;
  } [@@deriving json]


val userid_of_user : t -> id
val firstname_of_user : t -> string
val lastname_of_user : t -> string
val avatar_of_user : t -> string option
val avatar_uri_of_avatar :
  ?absolute_path:bool -> string -> Eliom_content.Xml.uri
val avatar_uri_of_user :
  ?absolute_path:bool -> t -> Eliom_content.Xml.uri option

(** Retrieve the full name of user. *)
val fullname_of_user : t -> string

(** Returns true if the firstname and the lastname of [t] has not
  * been completed yet. *)
val is_complete : t -> bool

[%%server.start]

val emails_of_user : t -> string Lwt.t

val add_actionlinkkey :
  (* by default, an action_link key is just an activation key *)
  ?autoconnect:bool -> (** default: false *)
  ?action:[ `AccountActivation | `PasswordReset | `Custom of string ] ->
  (** default: `AccountActivation *)
  ?data:string -> (** default: empty string *)
  ?validity:int64 -> (** default: 1L *)
  act_key:string -> userid:id -> email:string -> unit -> unit Lwt.t

val verify_password : email:string -> password:string -> id Lwt.t

(** returns user information.
    Results are cached in memory during page generation. *)
val user_of_userid : id -> t Lwt.t

val get_actionlinkkey_info : string -> Os_data.actionlinkkey_info Lwt.t
(** Retrieve the data corresponding to an action link key, each
    call decrements the validity of the key by 1 if it exists and
    validity > 0 (it remains at 0 if it's already 0). It is up to
    you to adapt the actions according to the value of validity!
    Raises [Os_db.No_such_resource] if the action link key is not found. *)

val userid_of_email : string -> id Lwt.t

(** Retrieve e-mails from user id. *)
val emails_of_userid : id -> string list Lwt.t

(** Retrieve the main e-mail of a user. *)
val email_of_user : t -> string Lwt.t

(** Retrieve the main e-mail from user id. *)
val email_of_userid : id -> string Lwt.t

(** Retrieve e-mails of a user. *)
val emails_of_user : t -> string list Lwt.t

(** Get users who match the [pattern] (useful for completion) *)
val get_users : ?pattern:string -> unit -> t list Lwt.t

(** Create a new user *)
val create :
  ?password:string -> ?avatar:string ->
  firstname:string -> lastname:string -> string -> t Lwt.t

(** Update the informations of a user. *)
val update :
  ?password:string -> ?avatar:string ->
  firstname:string -> lastname:string -> id -> unit Lwt.t

(** Another version of [update] using a type [t] instead of labels. *)
val update' : ?password:string -> t -> unit Lwt.t

(** Update the password only *)
val update_password : string -> id -> unit Lwt.t

(** Update the avatar only *)
val update_avatar : string -> id -> unit Lwt.t

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
                        (id -> string -> string -> bool) -> unit

(** Removes the email [email] from the user with the id [userid],
    if the email is registered as the main email for the user it fails
    with the exception [Main_email_removal_attempt].
*)
val remove_email_from_user : userid:id -> email:string -> unit Lwt.t

(** Returns whether for a user designated by its id the given email has been
    validated. *)
val email_is_validated : userid:id -> email:string -> bool Lwt.t

(** Returns whether an email is the  main email registered for a
    given user designated by its id. *)
val is_main_email : userid:id -> email:string -> bool Lwt.t

(** Sets the main email for a user with the id [userid] as the email [email]. *)
val update_main_email : userid:id -> email:string -> unit Lwt.t
