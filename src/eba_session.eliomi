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

(** Call this to add an action to be done on server side
    when the process starts *)
val on_start_process : (unit -> unit Lwt.t) -> unit

(** Call this to add an action to be done
    when the process starts in connected mode, or when the user logs in *)
val on_start_connected_process : (int64 -> unit Lwt.t) -> unit

(** Call this to add an action to be done at each connected request.
    The function takes the user id as parameter. *)
val on_connected_request : (int64 -> unit Lwt.t) -> unit

(** Call this to add an action to be done just after openning a session
    The function takes the user id as parameter. *)
val on_open_session : (int64 -> unit Lwt.t) -> unit

(** Call this to add an action to be done just before closing the session *)
val on_close_session : (unit -> unit Lwt.t) -> unit

(** Call this to add an action to be done just before handling a request *)
val on_request : (unit -> unit Lwt.t) -> unit

(** Call this to add an action to be done just for each denied request.
    The function takes the user id as parameter, if some user is connected. *)
val on_denied_request : (int64 option -> unit Lwt.t) -> unit


(** Scopes that are independant from user connection.
    Use this scopes for example when you want to store
    server side data for one browser or tab, but not user dependant.
    (Remains when user logs out).
*)
val user_indep_state_hierarchy : Eliom_common.scope_hierarchy
val user_indep_process_scope : Eliom_common.client_process_scope
val user_indep_session_scope : Eliom_common.session_scope

{shared{
exception Not_connected
exception Permission_denied
}}

module Make
  (C : Eba_config.Session)
  (Groups : Eba_sigs.Groups)
  : Eba_sigs.Session with type group = Groups.t
