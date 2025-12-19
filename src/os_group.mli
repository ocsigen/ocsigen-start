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
(** Exception raised when no there is no group corresponding to the request (for
    example wrong ID or name).
 *)

(* -----------------------------------------------------------------

   The implementation of this module should be sufficient. Groups are
   useful for example to allow or deny access to functions or pages.
*)

type id = Os_types.Group.id [@@deriving json]
(** Type alias to {!Os_types.Group.id} to allow to use [Os_group.id]. *)

type t = Os_types.Group.t = {id : id; name : string; desc : string option}
[@@deriving json]
(** Type alias to {!Os_types.Group.t} to allow to use [Os_group.t]. *)

val id_of_group : Os_types.Group.t -> Os_types.Group.id
(** [id_of_group group] returns the group ID. *)

val name_of_group : Os_types.Group.t -> string
(** [name_of_group group] returns the group name. *)

val desc_of_group : Os_types.Group.t -> string option
(** [desc_of_group group] returns the group description. *)

val create : ?description:string -> string -> Os_types.Group.t
(** [create ~description name] creates a new group in the database and returns
    it as a record of type [Os_types.Group.t]. *)

val group_of_name : string -> Os_types.Group.t
(** Overwrites the function [group_of_name] of [Os_db.Group] and use
    the [get] function of the cache module. *)

(* -----------------------------------------------------------------

   All the following functions are only helpers/wrappers around db
   functions ones. They generally use the type {!Os_types.group} of the module
   and get rid of the part of picking each field of the record
   {!os_types.group}.
*)

val add_user_in_group :
   group:Os_types.Group.t
  -> userid:Os_types.User.id
  -> unit
(** [add_user_in_group ~group ~userid] adds the user with ID [userid] to
    [group]. *)

val remove_user_in_group :
   group:Os_types.Group.t
  -> userid:Os_types.User.id
  -> unit
(** [remove_user_in_group ~group ~userid] removes the user with ID [userid] from
    [group]. *)

val in_group :
   ?dbh:PGOCaml.pa_pg_data PGOCaml.t
  -> group:Os_types.Group.t
  -> userid:Os_types.User.id
  -> unit
  -> bool
(** [in_group ~group ~userid] returns [true] if the user with ID [userid] is in
    [group]. *)

val all : unit -> Os_types.Group.t list
(** [all ()] returns all the groups of the database. *)
