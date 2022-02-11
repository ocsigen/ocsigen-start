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

(** This module defines low level functions for database requests. *)

open Resource_pooling
module PGOCaml : PGOCaml_generic.PGOCAML_GENERIC with type 'a monad = 'a Lwt.t

val init
  :  ?host:string
  -> ?port:int
  -> ?user:string
  -> ?password:string
  -> ?database:string
  -> ?unix_domain_socket_dir:string
  -> ?pool_size:int
  -> ?init:(PGOCaml.pa_pg_data PGOCaml.t -> unit Lwt.t)
  -> unit
  -> unit
(** [init ?host ?port ?user ?password ?database ?unix_domain_socket_dir ?init ()]
    initializes the variables for the database access and register a
    function [init] invoked each time a connection is created.
*)

val full_transaction_block
  :  (PGOCaml.pa_pg_data PGOCaml.t -> 'a Lwt.t)
  -> 'a Lwt.t
(** [full_transaction_block f] executes function [f] within a database
    transaction. The argument of [f] is a PGOCaml database handle. *)

val without_transaction : (PGOCaml.pa_pg_data PGOCaml.t -> 'a Lwt.t) -> 'a Lwt.t
(** [without_transaction f] executes function [f] outside a database
    transaction. The argument of [f] is a PGOCaml database handle. *)

val connection_pool : unit -> PGOCaml.pa_pg_data PGOCaml.t Resource_pool.t
(** Direct access to the connection pool *)

type wrapper =
  {f : 'a. PGOCaml.pa_pg_data PGOCaml.t -> (unit -> 'a Lwt.t) -> 'a Lwt.t}
(** Setup a wrapper function which is used each time a connection is
   acquired. This function can perform some actions before and/or
   after the connection is used. *)

val set_connection_wrapper : wrapper -> unit
