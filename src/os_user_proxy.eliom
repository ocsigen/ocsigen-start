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
    module Eliom_cscache>> which allows to keep synchronized the cache between
    the client and the server.
    Even if there is a cache implementing in {!Os_user} to avoid to do database
    requests, this last one is implementing only server side.

    TODO: This module must be compared to [Os_request_cache], [Eliom_cscache]
    and [Os_user.MCache]. The idea behind these different modules must be
    compared.
 *)

let%server cache : (Os_types.User.id, Os_types.User.t) Eliom_cscache.t =
  Eliom_cscache.create ()

let%server get_data_from_db myid_o userid =
  Os_user.user_of_userid userid

let%server get_data userid =
  let myid_o = Os_current_user.Opt.get_current_userid () in
  get_data_from_db myid_o userid

let%server get_data_from_db_for_client myid_o userid =
  get_data_from_db myid_o userid

let%server get_data_rpc' =
  Os_session.Opt.connected_rpc get_data_from_db_for_client

let%server get_data_rpc
  : (_, Os_types.User.t) Eliom_client.server_function =
  Eliom_client.server_function ~name:"os_user_proxy.get_data_rpc"
    [%json: Os_types.User.id] get_data_rpc'

let%client get_data_rpc = ~%get_data_rpc

let%client get_data id  = get_data_rpc id

let%shared get_data_from_cache userid =
  Eliom_cscache.find ~%cache get_data userid
