# Module `Session.Opt`

```ocaml
val connected_fun : 
  ?allow:Types.Group.t list ->
  ?deny:Types.Group.t list ->
  ?deny_fun:(Types.User.id option -> 'c Lwt.t) ->
  ?force_unconnected:bool ->
  (Types.User.id option -> 'a -> 'b -> 'c Lwt.t) ->
  'a ->
  'b ->
  'c Lwt.t
```
Same as [`connected_fun`](./#val-connected_fun) but instead of failing in case the user is not connected, the function given as parameter takes an `Types.User.id option` for user id.

```ocaml
val connected_rpc : 
  ?allow:Types.Group.t list ->
  ?deny:Types.Group.t list ->
  ?deny_fun:(Types.User.id option -> 'b Lwt.t) ->
  ?force_unconnected:bool ->
  (Types.User.id option -> 'a -> 'b Lwt.t) ->
  'a ->
  'b Lwt.t
```
Same as [`connected_rpc`](./#val-connected_rpc) but instead of failing in case the user is not connected, the function given as parameter takes an `Types.User.id option` for user id.
