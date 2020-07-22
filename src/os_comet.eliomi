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

(** This module provides function to monitor communications between the server
    clients.
    It's only defined for internal uses so not a lot of things are exported.
 *)

[%%shared.start]
val __link : unit

[%%client.start]

(** [restart_process ()] restarts the client.
    For mobile application, it restarts the application by going to
    ["index.html"].
    For other types of clients, <<a_api subproject="server" |
    module Eliom_service.reload_action>> is used as argument of <<a_api
    subproject="server" | module Eliom_client.exit_to>>
 *)
val restart_process :
  unit ->
  unit

val set_error_handler : (exn -> unit Lwt.t) -> unit
