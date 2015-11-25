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

(** Connection and disconnection of users,
    restrict access to services or server functions,
    define actions to be executed at some points of the session. *)

(** Call this to add an action to be done on server side
    when the process starts *)
val on_start_process : (unit -> unit Lwt.t) -> unit

(** Call this to add an action to be done
    when the process starts in connected mode, or when the user logs in *)
val on_start_connected_process : (int64 -> unit Lwt.t) -> unit

(** Call this to add an action to be done at each connected request.
    The function takes the user id as parameter. *)
val on_connected_request : (int64 -> unit Lwt.t) -> unit

(** Call this to add an action to be done just after opening a session
    The function takes the user id as parameter. *)
val on_open_session : (int64 -> unit Lwt.t) -> unit

(** Call this to add an action to be done just before closing the session *)
val on_pre_close_session : (unit -> unit Lwt.t) -> unit

(** Call this to add an action to be done just after closing the session *)
val on_post_close_session : (unit -> unit Lwt.t) -> unit

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

(** Open a session for a user by setting a session group for the browser
    which initiated the current request.
    Eliom base app is using both persistent and volatile session groups.
    The volatile groups is recreated from persistent group if absent.
*)
val connect : ?expire:float -> int64 -> unit Lwt.t

(** Close a session by discarding server side states for current browser
    (session and session group), current client process (tab) and current
    request.
    Only default Eliom scopes are affected, but not user independant scopes.
    The actions registered for session close (by {!on_close_session})
    will be executed just before the session is actually closed.
*)
val disconnect : unit -> unit Lwt.t

{shared{
(** Wrapper for service handlers that fetches automatically connection
    information.
    Register [(connected_fun f)] as handler for your services,
    where [f] is a function taking user id, GET parameters and POST parameters.
    If no user is connected, the service will fail by raising [Not_connected].
    Otherwise it calls function [f].
    To provide another behaviour in case the user is not connected,
    have a look at {!Opt.connected_fun} or module {!Eba_page}.

    Arguments [?allow] and [?deny] make possible to restrict access to some
    user groups. If access is denied, function [?deny_fun] will be called.
    By default, it raises {!Permission denied}.

    When called on client side, no security check is done.
*)
val connected_fun :
  ?allow:Eba_group.t list ->
  ?deny:Eba_group.t list ->
  ?deny_fun:(int64 option -> 'c Lwt.t) ->
  (int64 -> 'a -> 'b -> 'c Lwt.t) ->
  ('a -> 'b -> 'c Lwt.t)

(** Wrapper for server functions (see {!connected_fun}). *)
val connected_rpc :
  ?allow:Eba_group.t list ->
  ?deny:Eba_group.t list ->
  ?deny_fun:(int64 option -> 'b Lwt.t) ->
  (int64 -> 'a -> 'b Lwt.t) ->
  ('a -> 'b Lwt.t)

module Opt : sig

  (** Same as {!connected_fun} but instead of failing in case the user is
      not connected, the function given as parameter takes an [int64 option]
      for user id.
  *)
  val connected_fun :
    ?allow:Eba_group.t list ->
    ?deny:Eba_group.t list ->
    ?deny_fun:(int64 option -> 'c Lwt.t) ->
    (int64 option -> 'a -> 'b -> 'c Lwt.t) ->
    ('a -> 'b -> 'c Lwt.t)

  (** Same as {!connected_rpc} but instead of failing in case the user is
      not connected, the function given as parameter takes an [int64 option]
      for user id.
  *)
  val connected_rpc :
    ?allow:Eba_group.t list ->
    ?deny:Eba_group.t list ->
    ?deny_fun:(int64 option -> 'b Lwt.t) ->
    (int64 option -> 'a -> 'b Lwt.t) ->
    ('a -> 'b Lwt.t)

end
}}

(**/**)
{client{
   (** internal. Do not use *)
val get_current_userid_o : (unit -> int64 option) ref
 }}
