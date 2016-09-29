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

exception No_such_resource
exception Main_email_removal_attempt
exception Account_already_activated

val init :
  ?host:string ->
  ?port:int ->
  ?user:string ->
  ?password:string ->
  ?database:string ->
  ?unix_domain_socket_dir:string ->
  unit ->
  unit

val pwd_crypt_ref :
  ((string -> string) * (int64 -> string -> string -> bool)) ref

module Email : sig
  val available : string -> bool Lwt.t
end

module User : sig
  exception Invalid_action_link_key of int64

  val userid_of_email : string -> int64 Lwt.t

  val is_registered : string -> bool Lwt.t

  val get_email_validated : int64 -> string -> bool Lwt.t

  val set_email_validated : int64 -> string -> unit Lwt.t

  val add_actionlinkkey :
    ?autoconnect:bool ->
    ?action:[< `AccountActivation | `Custom of string | `PasswordReset
             > `AccountActivation ] ->
    ?data:string ->
    ?validity:int64 ->
    act_key:string -> userid:int64 -> email:string -> unit -> unit Lwt.t

  val add_preregister : string -> unit Lwt.t

  val remove_preregister : string -> unit Lwt.t

  val is_preregistered : string -> bool Lwt.t

  val all : ?limit:int64 -> unit -> string list Lwt.t

  val create :
    ?password:string ->
    ?avatar:string ->
    firstname:string -> lastname:string -> string -> int64 Lwt.t

  val update :
    ?password:string ->
    ?avatar:string ->
    firstname:string -> lastname:string -> int64 -> unit Lwt.t

  val update_password : string -> int64 -> unit Lwt.t

  val update_avatar : string -> int64 -> unit Lwt.t

  val update_main_email : userid:int64 -> email:string -> unit Lwt.t

  val verify_password : email:string -> password:string -> int64 Lwt.t

  val user_of_userid :
    int64 -> (int64 * string * string * string option * bool) Lwt.t

  val get_actionlinkkey_info : string -> Os_data.actionlinkkey_info Lwt.t

  val emails_of_userid : int64 -> string list Lwt.t

  val email_of_userid : int64 -> string Lwt.t

  val is_main_email : email:string -> userid:int64 -> bool Lwt.t

  val add_email_to_user : userid:int64 -> email:string -> unit Lwt.t

  val remove_email_from_user : userid:int64 -> email:string -> unit Lwt.t

  val get_users :
    ?pattern:string ->
    unit -> (int64 * string * string * string option * bool) list Lwt.t
end

module Groups : sig
  val create : ?description:string -> string -> unit Lwt.t

  val group_of_name : string -> (int64 * string * string option) Lwt.t

  val add_user_in_group : groupid:int64 -> userid:int64 -> unit Lwt.t

  val remove_user_in_group : groupid:int64 -> userid:int64 -> unit Lwt.t

  val in_group : groupid:int64 -> userid:int64 -> bool Lwt.t

  val all : unit -> (int64 * string * string option) list Lwt.t
end
