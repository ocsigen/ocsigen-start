
# Module `Make.Opt`

```ocaml
val connected_page : 
  ?allow:Os_types.Group.t list ->
  ?deny:Os_types.Group.t list ->
  ?predicate:(Os_types.User.id option -> 'a -> 'b -> bool Lwt.t) ->
  ?fallback:(Os_types.User.id option -> 'a -> 'b -> exn -> content Lwt.t) ->
  (Os_types.User.id option -> 'a -> 'b -> content Lwt.t) ->
  'a ->
  'b ->
  Html_types.html Eliom_content.Html.elt Lwt.t
```
Wrapper for pages that first checks if the user is connected. See [`Os_session.Opt.connected_fun`](./Os_session-Opt.md#val-connected_fun).
