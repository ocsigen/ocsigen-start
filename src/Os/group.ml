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

open Lwt.Syntax

exception No_such_group

type id = Types.Group.id [@@deriving json]

type t = Types.Group.t = {id : id; name : string; desc : string option}
[@@deriving json]

(** Create a group of type [Types.Group.t] using db information. *)
let create_group_from_db (groupid, name, description) : Types.Group.t =
  {id = groupid; name; desc = description}

let id_of_group (g : Types.Group.t) = g.id
let name_of_group (g : Types.Group.t) = g.name
let desc_of_group (g : Types.Group.t) = g.desc

(* Using cache tools to prevent multiple same database queries
   during the request. *)
module MCache = Request_cache.Make (struct
    type key = string
    type value = Types.Group.t

    let compare = compare

    let get key =
      Lwt.catch
        (fun () ->
           let* g = Db.Groups.group_of_name key in
           Lwt.return (create_group_from_db g))
        (function
          | Db.No_such_resource -> Lwt.fail No_such_group
          | exc -> Lwt.reraise exc)
  end)

(** Helper function which creates a new group and return it as
  * a record of type [Types.Group.t]. *)
let create ?description name =
  let group_of_name name =
    let* g = Db.Groups.group_of_name name in
    Lwt.return (create_group_from_db g)
  in
  Lwt.catch
    (fun () -> group_of_name name)
    (function
      | Db.No_such_resource ->
          let* () = Db.Groups.create ?description name in
          Lwt.catch
            (fun () ->
               let* g = group_of_name name in
               Lwt.return g)
            (function
              | Db.No_such_resource -> Lwt.fail No_such_group
              | exc -> Lwt.reraise exc)
      | exc -> Lwt.reraise exc)
(* Should never happen *)

(** Overwrite the function [group_of_name] of [Db.Group] and use
  * the [get] function of the cache module. *)
let group_of_name = MCache.get

(* -----------------------------------------------------------------
 *
 * All the following functions are only helpers/wrappers around db
 * functions ones. They generally use the type [Types.Group.t] of the module
 * and get rid of the part of picking each field of the record [Types.Group.t].
 *
 *)

let add_user_in_group ~(group : Types.Group.t) =
  Db.Groups.add_user_in_group ~groupid:group.id

let remove_user_in_group ~(group : Types.Group.t) =
  Db.Groups.remove_user_in_group ~groupid:group.id

let in_group ?dbh ~(group : Types.Group.t) ~userid () =
  Db.Groups.in_group ?dbh ~groupid:group.id ~userid ()

(** Returns all the groups of the database. *)
let all () =
  let* groups = Db.Groups.all () in
  Lwt.return (List.map create_group_from_db groups)
