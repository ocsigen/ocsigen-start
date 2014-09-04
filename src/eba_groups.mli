(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
 *
 * Copyright (C) 2014
 *      Charly Chevalier
 *      Vincent Balat
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

exception No_such_group

(* -----------------------------------------------------------------

   The implementation of this module should be sufficient. Groups are
   useful for example to allow or deny access to functions or pages.

*)

(** The type of a group *)
type t = {
  id : int64;
  name : string;
  desc : string option;
}

val id_of_group : t -> int64
val name_of_group : t -> string
val desc_of_group : t -> string option

(** Helper function which creates a new group and return it as
  * a record of type [t]. *)
val create : ?description:string -> string -> t Lwt.t

(** Overwrites the function [get_group] of [Eba_db.User] and use
  * the [get] function of the cache module. *)
val group_of_name : string -> t Lwt.t

(* -----------------------------------------------------------------

   All the followings functions are only helpers/wrappers around db
   functions ones. They generally use the type [t] of the module
   and get rid of the part of picking each field of the record [t].

*)

val add_user_in_group : group:t -> userid:int64 -> unit Lwt.t
val remove_user_in_group : group:t -> userid:int64 -> unit Lwt.t
val in_group : group:t -> userid:int64 -> bool Lwt.t

(** Returns all the groups of the database. *)
val all : unit -> t list Lwt.t
