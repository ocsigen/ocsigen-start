
# Module `Os_session`

Connection and disconnection of users, restrict access to services or server functions, define actions to be executed at some points of the session.

```ocaml
val on_start_process : (Os_types.User.id option -> unit Lwt.t) -> unit
```
Call this to add an action to be done on server side when the process starts

```ocaml
val on_start_connected_process : (Os_types.User.id -> unit Lwt.t) -> unit
```
Call this to add an action to be done when the process starts in connected mode, or when the user logs in

```ocaml
val on_start_unconnected_process : (unit -> unit Lwt.t) -> unit
```
Call this to add an action to be done on server side when the process starts but only when not in connected mode

```ocaml
val on_connected_request : (Os_types.User.id -> unit Lwt.t) -> unit
```
Call this to add an action to be done at each connected request. The function takes the user id as parameter.

```ocaml
val on_unconnected_request : (unit -> unit Lwt.t) -> unit
```
Call this to add an action to be done at each unconnected request.

```ocaml
val on_open_session : (Os_types.User.id -> unit Lwt.t) -> unit
```
Call this to add an action to be done just after opening a session The function takes the user id as parameter.

```ocaml
val on_pre_close_session : (unit -> unit Lwt.t) -> unit
```
Call this to add an action to be done just before closing the session

```ocaml
val on_post_close_session : (unit -> unit Lwt.t) -> unit
```
Call this to add an action to be done just after closing the session

```ocaml
val on_request : (Os_types.User.id option -> unit Lwt.t) -> unit
```
Call this to add an action to be done just before handling a request

```ocaml
val on_denied_request : (Os_types.User.id option -> unit Lwt.t) -> unit
```
Call this to add an action to be done just for each denied request. The function takes the user id as parameter, if some user is connected.

Scopes that are independent from user connection. Use this scopes for example when you want to store server side data for one browser or tab, but not user dependent. (Remains when user logs out).

```ocaml
val user_indep_state_hierarchy : Eliom_common.scope_hierarchy
```
```ocaml
val user_indep_process_scope : [> Eliom_common.client_process_scope ]
```
```ocaml
val user_indep_session_scope : [> Eliom_common.session_scope ]
```
```ocaml
exception Not_connected
```
```ocaml
exception Permission_denied
```
```ocaml
val connect : ?expire:bool -> Os_types.User.id -> unit Lwt.t
```
Close current session (if any) by calling disconnect, then open a new session for a user by setting a session group for the browser which initiated the current request. Ocsigen-start is using both persistent and volatile session groups. The volatile groups is recreated from persistent group if absent. By default, the connection does not expire; by setting the optional argument `expire` to true, the session will expire when the browser exits.

```ocaml
val disconnect_all : 
  ?sitedata:Eliom_common.sitedata ->
  ?userid:Os_types.User.id ->
  ?user_indep:bool ->
  ?with_restart:bool ->
  unit ->
  unit Lwt.t
```
Close all sessions of current user (or `userid` if present). If `?user_indep` is `true` (default), will also affect `user_indep_session_scope`. If `?with_restart` is `true` (default), will also restart the client. If you do not call the function during a request or during the initialisation phase of the Eliom module:

- `?userid` must not be `None`
- `?with_restart` must be `false`
- you must provide the extra parameter `?sitedata`, that you can get by calling `Eliom_request_info.get_sitedata` during the initialisation phase of the Eliom module.
```ocaml
val disconnect : unit -> unit Lwt.t
```
Close a session by discarding server side states for current browser (session and session group), current client process (tab) and current request. Only default Eliom scopes are affected, but not user independent scopes. The actions registered for session close (by `on_close_session`) will be executed just before the session is actually closed.

```ocaml
val connected_fun : 
  ?allow:Os_types.Group.t list ->
  ?deny:Os_types.Group.t list ->
  ?deny_fun:(Os_types.User.id option -> 'c Lwt.t) ->
  (Os_types.User.id -> 'a -> 'b -> 'c Lwt.t) ->
  'a ->
  'b ->
  'c Lwt.t
```
Wrapper for service handlers that fetches automatically connection information. Register `(connected_fun f)` as handler for your services, where `f` is a function taking user id, GET parameters and POST parameters. If no user is connected, the service will fail by raising `Not_connected`. Otherwise it calls function `f`. To provide another behaviour in case the user is not connected, have a look at [`Opt.connected_fun`](./Os_session-Opt.md#val-connected_fun) or module [`Os_page`](./Os_page.md).

Arguments `?allow` and `?deny` make possible to restrict access to some user groups. If access is denied, function `?deny_fun` will be called. By default, it raises `Permissiondenied`.

When called on client side, no security check is done.

If optional argument `force_unconnected` is `true`, it will not try to find session information, and behave as if user were not connected (default is `false`). This allows to use functions from module [`Os_current_user`](./Os_current_user.md) in functions outside application without failing.

Use only one connection wrapper for each request\!

```ocaml
val connected_rpc : 
  ?allow:Os_types.Group.t list ->
  ?deny:Os_types.Group.t list ->
  ?deny_fun:(Os_types.User.id option -> 'b Lwt.t) ->
  (Os_types.User.id -> 'a -> 'b Lwt.t) ->
  'a ->
  'b Lwt.t
```
Wrapper for server functions (see [`connected_fun`](./#val-connected_fun)).

```ocaml
val connected_wrapper : 
  ?allow:Os_types.Group.t list ->
  ?deny:Os_types.Group.t list ->
  ?deny_fun:(Os_types.User.id option -> 'b Lwt.t) ->
  ?force_unconnected:bool ->
  ('a -> 'b Lwt.t) ->
  'a ->
  'b Lwt.t
```
Wrapper for server functions when you do not need userid (see [`connected_fun`](./#val-connected_fun)). It is recommended to use this wrapper for all your server functions\!

```ocaml
module Opt : sig ... end
```