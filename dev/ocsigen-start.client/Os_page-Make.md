# Module `Os_page.Make`

## Parameters

```ocaml
module _ : PAGE
```

## Signature

```ocaml
val make_page : content -> [> Html_types.html ] Eliom_content.Html.elt
```
Builds a valid html page from body content by adding headers for this app

```ocaml
val page : 
  ?predicate:('a -> 'b -> bool Lwt.t) ->
  ?fallback:('a -> 'b -> exn -> content Lwt.t) ->
  ('a -> 'b -> content Lwt.t) ->
  'a ->
  'b ->
  Html_types.html Eliom_content.Html.elt Lwt.t
```
Default wrapper for service handler generating pages. It takes as parameter a function generating page content (body content) and transforms it into a function generating the whole page, according to the arguments given to the functor. Use the `predicate` function if you have something to check before the generation of the page. If `predicate` returns `false`, the page will be generated using the `fallback` function. The default fallback is the error page given as parameter to the functor.

```ocaml
module Opt : sig ... end
```
```ocaml
val connected_page : 
  ?allow:Os_types.Group.t list ->
  ?deny:Os_types.Group.t list ->
  ?predicate:(Os_types.User.id option -> 'a -> 'b -> bool Lwt.t) ->
  ?fallback:(Os_types.User.id option -> 'a -> 'b -> exn -> content Lwt.t) ->
  (Os_types.User.id -> 'a -> 'b -> content Lwt.t) ->
  'a ->
  'b ->
  Html_types.html Eliom_content.Html.elt Lwt.t
```
Wrapper for pages that first checks if the user is connected. See [`Os_session.connected_fun`](./Os_session.md#val-connected_fun).
