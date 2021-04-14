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

(** Connection and disconnection of users,
    restrict access to services or server functions,
    define actions to be executed at some points of the session. *)

(** Call this to add an action to be done on server side
    when the process starts *)
val on_start_process : (Os_types.User.id option -> unit Lwt.t) -> unit

(** Call this to add an action to be done
    when the process starts in connected mode, or when the user logs in *)
val on_start_connected_process : (Os_types.User.id -> unit Lwt.t) -> unit

(** Call this to add an action to be done on server side
    when the process starts but only when not in connected mode *)
val on_start_unconnected_process : (unit -> unit Lwt.t) -> unit

(** Call this to add an action to be done at each connected request.
    The function takes the user id as parameter. *)
val on_connected_request : (Os_types.User.id -> unit Lwt.t) -> unit

(** Call this to add an action to be done at each unconnected request. *)
val on_unconnected_request : (unit -> unit Lwt.t) -> unit

(** Call this to add an action to be done just after opening a session
    The function takes the user id as parameter. *)
val on_open_session : (Os_types.User.id -> unit Lwt.t) -> unit

(** Call this to add an action to be done just before closing the session *)
val on_pre_close_session : (unit -> unit Lwt.t) -> unit

(** Call this to add an action to be done just after closing the session *)
val on_post_close_session : (unit -> unit Lwt.t) -> unit

(** Call this to add an action to be done just before handling a request *)
val on_request : (Os_types.User.id option -> unit Lwt.t) -> unit

(** Call this to add an action to be done just for each denied request.
    The function takes the user id as parameter, if some user is connected. *)
val on_denied_request : (Os_types.User.id option -> unit Lwt.t) -> unit


(** Scopes that are independent from user connection.
    Use this scopes for example when you want to store
    server side data for one browser or tab, but not user dependent.
    (Remains when user logs out).
*)
val user_indep_state_hierarchy : Eliom_common.scope_hierarchy
val user_indep_process_scope : [> Eliom_common.client_process_scope ]
val user_indep_session_scope : [> Eliom_common.session_scope ]

[%%shared.start]
exception Not_connected
exception Permission_denied

[%%server.start]
(** Open a session for a user by setting a session group for the browser
    which initiated the current request.
    Ocsigen-start is using both persistent and volatile session groups.
    The volatile groups is recreated from persistent group if absent.
    By default, the connection does not expire; by setting the optional
    argument [expire] to true, the session will expire when the browser
    exits.
*)
val connect : ?expire:bool -> Os_types.User.id -> unit Lwt.t

(** Close all sessions of current user (or [userid] if present).
    If [?user_indep] is [true]
    (default), will also affect [user_indep_session_scope].
*)
val disconnect_all :
  ?userid:Os_types.User.id -> ?user_indep:bool -> unit -> unit Lwt.t

[%%client.start]
(** Close all sessions of current user.
    If [?user_indep] is [true] (default),
    will also affect [user_indep_session_scope].
*)
val disconnect_all : ?user_indep:bool -> unit -> unit Lwt.t

[%%shared.start]
(** Close a session by discarding server side states for current browser
    (session and session group), current client process (tab) and current
    request.
    Only default Eliom scopes are affected, but not user independent scopes.
    The actions registered for session close (by {!on_close_session})
    will be executed just before the session is actually closed.
*)
val disconnect : unit -> unit Lwt.t

(** Wrapper for service handlers that fetches automatically connection
    information.
    Register [(connected_fun f)] as handler for your services,
    where [f] is a function taking user id, GET parameters and POST parameters.
    If no user is connected, the service will fail by raising [Not_connected].
    Otherwise it calls function [f].
    To provide another behaviour in case the user is not connected,
    have a look at {!Opt.connected_fun} or module {!Os_page}.

    Arguments [?allow] and [?deny] make possible to restrict access to some
    user groups. If access is denied, function [?deny_fun] will be called.
    By default, it raises {!Permission denied}.

    When called on client side, no security check is done.

    If optional argument [force_unconnected] is [true],
    it will not try to find session information, and behave as if user were
    not connected (default is [false]). This allows to use functions
    from module {!Os_current_user} in functions outside application
    without failing.

    Use only one connection wrapper for each request!
*)
val connected_fun :
  ?allow:Os_types.Group.t list ->
  ?deny:Os_types.Group.t list ->
  ?deny_fun:(Os_types.User.id option -> 'c Lwt.t) ->
  (Os_types.User.id -> 'a -> 'b -> 'c Lwt.t) ->
  ('a -> 'b -> 'c Lwt.t)

(** Wrapper for server functions (see {!connected_fun}). *)
val connected_rpc :
  ?allow:Os_types.Group.t list ->
  ?deny:Os_types.Group.t list ->
  ?deny_fun:(Os_types.User.id option -> 'b Lwt.t) ->
  (Os_types.User.id -> 'a -> 'b Lwt.t) ->
  ('a -> 'b Lwt.t)

(** Wrapper for server functions when you do not need userid
    (see {!connected_fun}).
    It is recommended to use this wrapper for all your server functions! *)
val connected_wrapper :
  ?allow:Os_types.Group.t list ->
  ?deny:Os_types.Group.t list ->
  ?deny_fun:(Os_types.User.id option -> 'b Lwt.t) ->
  ?force_unconnected:bool ->
  ('a -> 'b Lwt.t) ->
  ('a -> 'b Lwt.t)

module Opt : sig

  (** Same as {!connected_fun} but instead of failing in case the user is
      not connected, the function given as parameter takes an [Os_types.User.id
      option] for user id.
  *)
  val connected_fun :
    ?allow:Os_types.Group.t list ->
    ?deny:Os_types.Group.t list ->
    ?deny_fun:(Os_types.User.id option -> 'c Lwt.t) ->
    ?force_unconnected:bool ->
    (Os_types.User.id option -> 'a -> 'b -> 'c Lwt.t) ->
    ('a -> 'b -> 'c Lwt.t)

  (** Same as {!connected_rpc} but instead of failing in case the user is
      not connected, the function given as parameter takes an [Os_types.User.id
      option] for user id.
  *)
  val connected_rpc :
    ?allow:Os_types.Group.t list ->
    ?deny:Os_types.Group.t list ->
    ?deny_fun:(Os_types.User.id option -> 'b Lwt.t) ->
    ?force_unconnected:bool ->
    (Os_types.User.id option -> 'a -> 'b Lwt.t) ->
    ('a -> 'b Lwt.t)

end


(**/**)
[%%client.start]
   (** internal. Do not use *)
val get_current_userid_o : (unit -> Os_types.User.id option) ref

[%%server.start]
val set_warn_connection_change :
  (([ `Session ], [ `Data ]) Eliom_state.Ext.state -> unit) ->
  unit
