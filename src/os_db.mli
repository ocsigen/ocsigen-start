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

(** This module defines low level functions for database requests. *)

(** Exception raised when no ressource corresponds to the database request. *)
exception No_such_resource

(** Exception raised when there is an attempt to remove the main email. *)
exception Main_email_removal_attempt

(** Exception raised when the account is not activated. *)
exception Account_not_activated

(** Lwt version of PGOCaml *)
module PGOCaml : PGOCaml_generic.PGOCAML_GENERIC with type 'a monad = 'a Lwt.t

(** [init ?host ?port ?user ?password ?database ?unix_domain_socket_dir ?init ()]
    initializes the variables for the database access and register a
    function [init] invoked each time a connection is created.
*)
val init :
  ?host:string ->
  ?port:int ->
  ?user:string ->
  ?password:string ->
  ?database:string ->
  ?unix_domain_socket_dir:string ->
  ?pool_size:int ->
  ?init:(PGOCaml.pa_pg_data PGOCaml.t -> unit Lwt.t) ->
  unit ->
  unit


(** [full_transaction_block f] executes function [f] within a database
    transaction. The argument of [f] is a PGOCaml database handle. *)
val full_transaction_block :
  (PGOCaml.pa_pg_data PGOCaml.t -> 'a Lwt.t) -> 'a Lwt.t

(** [without_transaction f] executes function [f] outside a database
    transaction. The argument of [f] is a PGOCaml database handle. *)
val without_transaction :
  (PGOCaml.pa_pg_data PGOCaml.t -> 'a Lwt.t) -> 'a Lwt.t

(** [pwd_crypt_ref] is a reference to [(f_crypt, f_check)] where
    - [f_crypt pwd] is used to encrypt the password [pwd].
    - [f_check userid pwd hashed_pwd] returns [true] if the hash of [pwd] and
    the hashed password [hashed_pwd] of the user with id [userid] match. If they
    don't match, it returns [false].
 *)
val pwd_crypt_ref :
  ((string -> string) * (Os_types.User.id -> string -> string -> bool)) ref

(** This module is used for low-level email management with database. *)
module Email : sig
  (** [available email] returns [true] if [email] is not already used. Else, it
      returns [false].
   *)
  val available : string -> bool Lwt.t
end

(** This module is used for low-level user management with database. *)
module User : sig
  exception Invalid_action_link_key of Os_types.User.id

  (** [userid_of_email email] returns the userid of the user which has the email
      [email]. *)
  val userid_of_email : string -> Os_types.User.id Lwt.t

  (** [is_registered email] returns [true] if the email is already registered.
      Else, it returns [false]. *)
  val is_registered : string -> bool Lwt.t

  (** [is_email_validated userid email] returns [true] if [email] has been
      validated by the user with id [userid]. *)
  val is_email_validated : Os_types.User.id -> string -> bool Lwt.t

  (** [set_email_validated userid email] valids [email] for the user with id
      [userid]. *)
  val set_email_validated : Os_types.User.id -> string -> unit Lwt.t

  val add_actionlinkkey :
    ?autoconnect:bool ->
    ?action:[< `AccountActivation | `Custom of string | `PasswordReset
             > `AccountActivation ] ->
    ?data:string ->
    ?validity:int64 ->
    act_key:string ->
    userid:Os_types.User.id ->
    email:string ->
    unit ->
    unit Lwt.t

  (** [add_preregister email] preregisters [email] in the database. *)
  val add_preregister : string -> unit Lwt.t

  (** [remove_preregister email] removes [email] from the database. *)
  val remove_preregister : string -> unit Lwt.t

  (** [is_preregistered email] returns [true] if [email] is already
      registered. Else, it returns [false]. *)
  val is_preregistered : string -> bool Lwt.t

  (** [all ?limit ()] get all email addresses with a limit of [limit] (default
      is 10). *)
  val all : ?limit:int64 -> unit -> string list Lwt.t

  (** [create ?password ?avatar ?language ~firstname ~lastname email] creates a new user
      in the database and returns the userid of the new user.
      Email, first name, last name and language are mandatory to create a new
      user.
      If [password] is passed as an empty string, it fails with the message
      ["empty password"]. TODO: change it to an exception?
   *)
  val create :
    ?password:string ->
    ?avatar:string ->
    ?language:string ->
    ?email:string ->
    firstname:string -> lastname:string -> unit -> Os_types.User.id Lwt.t

  (** [update ?password ?avatar ?language ~firstname ~lastname userid] updates the user
      profile with [userid].
      If [password] is passed as an empty string, it fails with the message
      ["empty password"]. TODO: change it to an exception?
   *)
  val update :
    ?password:string ->
    ?avatar:string ->
    ?language:string ->
    firstname:string -> lastname:string -> Os_types.User.id -> unit Lwt.t

  (** [update_password ~userid ~new_password] updates the password of the user
      with ID [userid].
      If [password] is passed as an empty string, it fails with the message
      ["empty password"]. TODO: change it to an exception?
   *)
  val update_password :
    userid:Os_types.User.id -> password:string -> unit Lwt.t

  (** [update_avatar ~userid ~avatar] updates the avatar of the user
      with ID [userid]. *)
  val update_avatar : userid:Os_types.User.id -> avatar:string -> unit Lwt.t

  (** [update_main_email ~userid ~email] updates the main email of the user
      with ID [userid]. *)
  val update_main_email : userid:Os_types.User.id -> email:string -> unit Lwt.t

  (** [update_language ~userid ~language] updates the language of the user with
      ID [userid].
   *)
  val update_language : userid:Os_types.User.id -> language:string -> unit Lwt.t

  (** [verify_password ~email ~password] returns the userid if user with email
      [email] is registered with the password [password]. If [password] is empty
      or if the password is wrong, it fails with {!No_such_resource}. *)
  val verify_password : email:string -> password:string -> Os_types.User.id Lwt.t

  (** [verify_password_phone ~number ~password] returns the userid of
      the user who owns [number] and whose password is [password]. If
      [password] is empty or if the password is wrong, it fails with
      {!No_such_resource}. *)
  val verify_password_phone :
    number:string -> password:string -> Os_types.User.id Lwt.t

  (** [user_of_userid userid] returns a tuple [(userid, firstname, lastname,
      avatar, bool_password, language)] describing the information about
      the user with ID [userid].
      [bool_password] is a boolean. Its value is [true] if a password has been
      set. Else [false].
      If there is no such user, it fails with {!No_such_resource}.
   *)
  val user_of_userid :
    Os_types.User.id ->
    (Os_types.User.id * string * string * string option * bool * string option) Lwt.t

  (** [get_actionlinkkey_info key] returns the information about the
      action link [key] as a type {!Os_types.Action_link_key.info}. *)
  val get_actionlinkkey_info : string -> Os_types.Action_link_key.info Lwt.t

  (** [emails_of_userid userid] returns all emails registered for the user with
      ID [userid].
      If there is no user with [userid] as ID, it fails with
      {!No_such_resource}.
      *)
  val emails_of_userid : Os_types.User.id -> string list Lwt.t

  (** Like [emails_of_userid], but also returns validation
      status. This way we perform fewer DB queries. *)
  val emails_of_userid_with_status :
    Os_types.User.id -> (string * bool) list Lwt.t

  (** [email_of_userid userid] returns the main email registered for the user
      with ID [userid].
      If there is no such user, it fails with
      {!No_such_resource}.
      *)
  val email_of_userid : Os_types.User.id -> string option Lwt.t

  (** [is_main_email ~email ~userid] returns [true] if the main email of the
      user with ID [userid] is [email].
      If there is no such user or if [email] is not the main
      email, it returns [false].
   *)
  val is_main_email : userid:Os_types.User.id -> email:string -> bool Lwt.t

  (** [add_email_to_user ~userid ~email] add [email] to user with ID [userid].
    *)
  val add_email_to_user : userid:Os_types.User.id -> email:string -> unit Lwt.t

  (** [remove_email_from_user ~userid ~email] removes the email [email] from the
      emails list of user with ID [userid].
      If [email] is the main email, it fails with {!Main_email_removal_attempt}.
   *)
  val remove_email_from_user :
    userid:Os_types.User.id ->
    email:string ->
    unit Lwt.t

  (** [get_language userid] returns the language of the user with ID [userid] *)
  val get_language : Os_types.User.id -> string option Lwt.t

  (** [get_users ~pattern ()] returns all users matching the pattern [pattern]
      as a tuple [(userid, firstname, lastname, avatar, bool_password,
      language)].
  *)
  val get_users :
    ?pattern:string ->
    unit ->
    (Os_types.User.id * string * string * string option * bool * string option) list Lwt.t
end

(** This module is low-level and used to manage groups of user. *)
module Groups : sig
  (** [create ?description name] creates a new group with name [name] and with
      description [description]. *)
  val create : ?description:string -> string -> unit Lwt.t

  (** [group_of_name name] returns a tuple [(groupid, name, description)]
      describing the group.
      If no group has the name [name], it fails with {!No_such_resource}.
   *)
  val group_of_name :
    string ->
    (Os_types.Group.id * string * string option) Lwt.t

  (** [add_user_in_group ~groupid ~userid] adds the user with ID [userid] in the
      group with ID [groupid] *)
  val add_user_in_group :
    groupid:Os_types.Group.id ->
    userid:Os_types.User.id ->
    unit Lwt.t

  (** [remove_user_in_group ~groupid ~userid] removes the user with ID [userid]
      in the group with ID [groupid] *)
  val remove_user_in_group :
    groupid:Os_types.Group.id ->
    userid:Os_types.User.id ->
    unit Lwt.t

  (** [in_group ~groupid ~userid] returns [true] if the user with ID [userid] is
      in the group with ID [groupid]. *)
  val in_group :
    ?dbh: PGOCaml.pa_pg_data PGOCaml.t ->
    groupid:Os_types.Group.id ->
    userid:Os_types.User.id ->
    unit ->
    bool Lwt.t

  (** [all ()] returns all groups as list of tuple [(groupid, name,
      description)]. *)
  val all : unit -> (Os_types.Group.id * string * string option) list Lwt.t
end

(** Manage user phone numbers *)
module Phone : sig

  (** [add userid number] associates [number] with the user
      [userid]. Returns [true] on success. *)
  val add : int64 -> string -> bool Lwt.t

  (** Does the number exist in the database? *)
  val exists : string -> bool Lwt.t

  (** The user corresponding to a phone number (if any). *)
  val userid : string -> Os_types.User.id option Lwt.t

  (** [delete userid number] deletes [number], which has to be
      associated to [userid]. *)
  val delete : int64 -> string -> unit Lwt.t

  (** [get_list userid] returns the list of number associated to the
      user. *)
  val get_list : int64 -> string list Lwt.t

end
