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

[%%server.start]

val cache : (Os_types.User.id, Os_types.User.t) Eliom_cscache.t

val get_data_from_db : 'a -> Os_types.User.id -> Os_types.User.t Lwt.t

val get_data : Os_types.User.id -> Os_types.User.t Lwt.t

val get_data_from_db_for_client : 'a -> Os_types.User.id -> Os_types.User.t Lwt.t

val get_data_rpc' : Os_types.User.id -> Os_types.User.t Lwt.t

[%%client.start]

val get_data_rpc' : unit

val get_data : Os_types.User.id -> Os_types.User.t Lwt.t

[%%shared.start]

val get_data_rpc : (Os_types.User.id, Os_types.User.t) Eliom_client.server_function

val get_data_from_cache : Os_types.User.id -> Os_types.User.t Lwt.t
