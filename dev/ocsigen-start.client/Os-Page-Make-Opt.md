# Module `Make.Opt`

```ocaml
val connected_page : 
  ?allow:Types.Group.t list ->
  ?deny:Types.Group.t list ->
  ?predicate:(Types.User.id option -> 'a -> 'b -> bool Lwt.t) ->
  ?fallback:(Types.User.id option -> 'a -> 'b -> exn -> content Lwt.t) ->
  (Types.User.id option -> 'a -> 'b -> content Lwt.t) ->
  'a ->
  'b ->
  Html_types.html Eliom.Content.Html.elt Lwt.t
```
Wrapper for pages that first checks if the user is connected. See [`Session.Opt.connected_fun`](./Os-Session-Opt.md#val-connected_fun).
