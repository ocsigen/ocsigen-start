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

(** This module provides functions and types to manage the current user. *)

(** On server side, this will work only if the current request in wrapped
    in {!Os_session.connected_wrapper}, or {!Os_session.connected_fun},
    etc.
*)

type current_user =
  | CU_idontknown
  | CU_notconnected
  | CU_user of Os_types.User.t

(** [get_current_user ()] returns the current user as a {!Os_types.User.t} type.
    If no user is connected, it fails with {!Os_session.Not_connected}. *)
val get_current_user : unit -> Os_types.User.t

(** [get_current_userid ()] returns the ID of the current user.
    If no user is connected, it fails with {!Os_session.Not_connected}. *)
val get_current_userid : unit -> Os_types.User.id

(** Instead of exception, the module [Opt] returns an option. *)
module Opt : sig
  (** [get_current_user ()] returns the current user as a [Os_types.User.t option]
      type. If no user is connected, [None] is returned. *)
  val get_current_user : unit -> Os_types.User.t option

  (** [get_current_userid ()] returns the ID of the current user as an option.
      If no user is connected, [None] is returned. *)
  val get_current_userid : unit -> Os_types.User.id option
end

(** [remove_email_from_user email] removes the email [email] of the current
    user.
    If no user is connected, it fails with {!Os_session.Not_connected}. If
    [email] is the main email of the current user, it fails with
    {!Os_db.Main_email_removal_attempt}.
 *)
val remove_email_from_user : string -> unit Lwt.t

(** [update_main_email email] sets the main email of the current user to
    [email].
    If no user is connected, it fails with {!Os_session.Not_connected}.
 *)
val update_main_email : string -> unit Lwt.t

[%%server.start]

(** [is_email_validated email] returns [true] if [email] is a valided email for
    the current user.
    If no user is connected, it fails with {!Os_session.Not_connected}.
    It returns [false] in all other cases.
 *)
val is_email_validated : string -> bool Lwt.t

(** [is_main_email email] returns [true] if [email] is the main email of the current user. *)
val is_main_email : string -> bool Lwt.t

[%%client.start]

val me : current_user ref
