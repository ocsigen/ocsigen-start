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

type id = Types.Group.id [@@deriving json]
(** Type alias to {!Types.Group.id} to allow to use [Group.id]. *)

type t = Types.Group.t = {id : id; name : string; desc : string option}
[@@deriving json]
(** Type alias to {!Types.Group.t} to allow to use [Group.t]. *)

val id_of_group : Types.Group.t -> Types.Group.id
(** [id_of_group group] returns the group ID. *)

val name_of_group : Types.Group.t -> string
(** [name_of_group group] returns the group name. *)

val desc_of_group : Types.Group.t -> string option
(** [desc_of_group group] returns the group description. *)

val create : ?description:string -> string -> Types.Group.t Lwt.t
(** [create ?description name] returns the group named [name], and creates it
    in the database first if it does not exist. [description] is used only
    when the group is created. *)

val group_of_name : string -> Types.Group.t Lwt.t
(** [group_of_name name] returns the group named [name]. The result is cached
    for the duration of the request. Fails with {!No_such_group} if there is
    no such group. *)

(* -----------------------------------------------------------------

   All the following functions are only helpers/wrappers around db
   functions ones. They generally use the type {!Types.group} of the module
   and get rid of the part of picking each field of the record
   {!os_types.group}.
*)

val add_user_in_group :
  group:Types.Group.t -> userid:Types.User.id -> unit Lwt.t
(** [add_user_in_group ~group ~userid] adds the user with ID [userid] to
    [group]. *)

val remove_user_in_group :
  group:Types.Group.t -> userid:Types.User.id -> unit Lwt.t
(** [remove_user_in_group ~group ~userid] removes the user with ID [userid] from
    [group]. *)

val in_group :
     ?dbh:Db.PGOCaml.pa_pg_data Db.PGOCaml.t
  -> group:Types.Group.t
  -> userid:Types.User.id
  -> unit
  -> bool Lwt.t
(** [in_group ~group ~userid] returns [true] if the user with ID [userid] is in
    [group]. *)

val all : unit -> Types.Group.t list Lwt.t
(** [all ()] returns all the groups of the database. *)
