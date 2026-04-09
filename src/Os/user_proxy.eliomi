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

(** This module implements a cache of user using <<a_api project="eliom" |
    module Eliom.Cscache>> which allows to keep synchronized the cache between
    the client and the server.
    Even if there is a cache implemented in {!User} to avoid to do database
    requests, this last one is implementing only server side. Same for
    {!Request_cache} which is also only server-side.
 *)

[%%server.start]

val cache : (Types.User.id, Types.User.t) Eliom.Cscache.t
(** Cache keeping userid and user information as a {!Types.user} type. *)

val get_data_from_db : 'a -> Types.User.id -> Types.User.t Lwt.t
(** [get_data_from_db myid_o userid] returns the user which has ID [userid].
    For the moment, [myid_o] is not used but it will be use later.

    Data comes from the database, not the cache.
 *)

val get_data_from_db_for_client : 'a -> Types.User.id -> Types.User.t Lwt.t
(** [get_data_from_db_for_client myid_o userid] returns the user which has ID
    [userid]. For the moment, [myid_o] is not used but it will be use later.

    Data comes from the database, not the cache.
 *)

[%%shared.start]

val get_data : Types.User.id -> Types.User.t Lwt.t
(** [get_data userid] returns the user which has ID [userid].
    For the moment, [myid_o] is not used but it will be use later.

    Data comes from the database, not the cache.
 *)

val get_data_from_cache : Types.User.id -> Types.User.t Lwt.t
(** [get_data_from_cache userid] returns the user with ID [userid] saved in
    cache.
 *)
