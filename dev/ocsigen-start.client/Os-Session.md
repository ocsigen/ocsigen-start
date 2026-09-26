# Module `Os.Session`

```ocaml
exception Not_connected
```
```ocaml
exception Permission_denied
```
```ocaml
val disconnect_all : ?user_indep:bool -> unit -> unit Lwt.t
```
Close all sessions of current user. If `?user_indep` is `true` (default), will also affect `user_indep_session_scope`.

```ocaml
val disconnect : unit -> unit Lwt.t
```
Close a session by discarding server side states for current browser (session and session group), current client process (tab) and current request. Only default Eliom scopes are affected, but not user independent scopes. The actions registered for session close (by `on_close_session`) will be executed just before the session is actually closed.

```ocaml
val connected_fun : 
  ?allow:Types.Group.t list ->
  ?deny:Types.Group.t list ->
  ?deny_fun:(Types.User.id option -> 'c Lwt.t) ->
  (Types.User.id -> 'a -> 'b -> 'c Lwt.t) ->
  'a ->
  'b ->
  'c Lwt.t
```
Wrapper for service handlers that fetches automatically connection information. Register `(connected_fun f)` as handler for your services, where `f` is a function taking user id, GET parameters and POST parameters. If no user is connected, the service will fail by raising `Not_connected`. Otherwise it calls function `f`. To provide another behaviour in case the user is not connected, have a look at [`Opt.connected_fun`](./Os-Session-Opt.md#val-connected_fun) or module [`Page`](./Os-Page.md).

Arguments `?allow` and `?deny` make possible to restrict access to some user groups. If access is denied, function `?deny_fun` will be called. By default, it raises `Permissiondenied`.

When called on client side, no security check is done.

If optional argument `force_unconnected` is `true`, it will not try to find session information, and behave as if user were not connected (default is `false`). This allows to use functions from module [`Current_user`](./Os-Current_user.md) in functions outside application without failing.

Use only one connection wrapper for each request\!

```ocaml
val connected_rpc : 
  ?allow:Types.Group.t list ->
  ?deny:Types.Group.t list ->
  ?deny_fun:(Types.User.id option -> 'b Lwt.t) ->
  (Types.User.id -> 'a -> 'b Lwt.t) ->
  'a ->
  'b Lwt.t
```
Wrapper for server functions (see [`connected_fun`](./#val-connected_fun)).

```ocaml
val connected_wrapper : 
  ?allow:Types.Group.t list ->
  ?deny:Types.Group.t list ->
  ?deny_fun:(Types.User.id option -> 'b Lwt.t) ->
  ?force_unconnected:bool ->
  ('a -> 'b Lwt.t) ->
  'a ->
  'b Lwt.t
```
Wrapper for server functions when you do not need userid (see [`connected_fun`](./#val-connected_fun)). It is recommended to use this wrapper for all your server functions\!

```ocaml
module Opt : sig ... end
```
