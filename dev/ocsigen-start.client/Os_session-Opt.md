# Module `Os_session.Opt`

```ocaml
val connected_fun : 
  ?allow:Os_types.Group.t list ->
  ?deny:Os_types.Group.t list ->
  ?deny_fun:(Os_types.User.id option -> 'c Lwt.t) ->
  ?force_unconnected:bool ->
  (Os_types.User.id option -> 'a -> 'b -> 'c Lwt.t) ->
  'a ->
  'b ->
  'c Lwt.t
```
Same as [`connected_fun`](./#val-connected_fun) but instead of failing in case the user is not connected, the function given as parameter takes an `Os_types.User.id option` for user id.

```ocaml
val connected_rpc : 
  ?allow:Os_types.Group.t list ->
  ?deny:Os_types.Group.t list ->
  ?deny_fun:(Os_types.User.id option -> 'b Lwt.t) ->
  ?force_unconnected:bool ->
  (Os_types.User.id option -> 'a -> 'b Lwt.t) ->
  'a ->
  'b Lwt.t
```
Same as [`connected_rpc`](./#val-connected_rpc) but instead of failing in case the user is not connected, the function given as parameter takes an `Os_types.User.id option` for user id.
