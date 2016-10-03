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

(** Groups of users.
    Groups are sets of users. Groups and group members are saved in database.
    Groups are used by OS for example to restrict access to pages or
    server functions. *)

exception No_such_group

(* -----------------------------------------------------------------

   The implementation of this module should be sufficient. Groups are
   useful for example to allow or deny access to functions or pages.

*)

(** The type of a group *)
type t

(** [id_of_group group] returns the group ID. *)
val id_of_group : t -> Os_types.groupid

(** [name_of_group group] returns the group name. *)
val name_of_group : t -> string

(** [desc_of_group group] returns the group description. *)
val desc_of_group : t -> string option

(** [create ~description name] creates a new group in the database and returns
    it as a record of type [t]. *)
val create : ?description:string -> string -> t Lwt.t

(** Overwrites the function [get_group] of [Os_db.User] and use
    the [get] function of the cache module. *)
val group_of_name : string -> t Lwt.t

(* -----------------------------------------------------------------

   All the followings functions are only helpers/wrappers around db
   functions ones. They generally use the type [t] of the module
   and get rid of the part of picking each field of the record [t].

*)

(** [add_user_in_group ~group ~userid] adds the user with ID [userid] to
    [group]. *)
val add_user_in_group : group:t -> userid:Os_types.userid -> unit Lwt.t

(** [remove_user_in_group ~group ~userid] removes the user with ID [userid] from
    [group]. *)
val remove_user_in_group : group:t -> userid:Os_types.userid -> unit Lwt.t

(** [in_group ~group ~userid] returns [true] if the user with ID [userid] is in
    [group]. *)
val in_group : group:t -> userid:Os_types.userid -> bool Lwt.t

(** [all ()] returns all the groups of the database. *)
val all : unit -> t list Lwt.t
