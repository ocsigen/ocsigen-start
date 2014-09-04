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
 *
 * The implementation of this module should be sufficient. Groups are
 * needed by EBA to allow or deny access to functions or pages.
 *
 * EBA uses only the type [t] of the module and the [in_group] function
 * to know if a userid belongs to a group.
 *
 * *)

(** The type of a group *)
type t = {
  id : int64;
  name : string;
  desc : string option;
}

(** Create a group of type [t] using db informations. *)
let create_group_from_db (groupid, name, description) = {
  id = groupid;
  name = name;
  desc = description;
}

let id_of_group g = g.id
let name_of_group g = g.name
let desc_of_group g = g.desc

(* Using cache tools to prevent multiple same database queries
   during the request. *)
module MCache = Eba_tools.Cache_f.Make(
struct
  type key_t = string
  type value_t = t

  let compare = compare
  let get key =
    try_lwt
      lwt g = Eba_db.Groups.group_of_name key in
      Lwt.return (create_group_from_db g)
    with Eba_db.No_such_resource -> Lwt.fail No_such_group
end)

(** Helper function which creates a new group and return it as
  * a record of type [t]. *)
let create ?description name =
  let group_of_name name =
    lwt g = Eba_db.Groups.group_of_name name in
    Lwt.return (create_group_from_db g)
  in
  try_lwt group_of_name name with
  | Eba_db.No_such_resource ->
    lwt () = Eba_db.Groups.create ?description name in
    try_lwt
      lwt g = group_of_name name in
      Lwt.return g
    with Eba_db.No_such_resource ->
      Lwt.fail No_such_group (* Should never happen *)

(** Overwrite the function [group_of_name] of [Eba_db.User] and use
  * the [get] function of the cache module. *)
let group_of_name = MCache.get

(* -----------------------------------------------------------------
 *
 * All the followings functions are only helpers/wrappers around db
 * functions ones. They generally use the type [t] of the module
 * and get rid of the part of picking each field of the record [t].
 *
 * *)

let add_user_in_group ~group =
  Eba_db.Groups.add_user_in_group ~groupid:(group.id)
let remove_user_in_group ~group =
  Eba_db.Groups.remove_user_in_group ~groupid:(group.id)
let in_group ~group =
  Eba_db.Groups.in_group ~groupid:(group.id)

(** Returns all the groups of the database. *)
let all () =
  lwt groups = Eba_db.Groups.all () in
  Lwt.return (List.map (create_group_from_db) groups)
