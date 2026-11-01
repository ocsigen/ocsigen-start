# Module `Page.Make`

## Parameters

```ocaml
module _ : PAGE
```

## Signature

```ocaml
val make_page : content -> [> Html_types.html ] Eliom.Content.Html.elt
```
Builds a valid html page from body content by adding headers for this app

```ocaml
val page : 
  ?predicate:('a -> 'b -> bool Lwt.t) ->
  ?fallback:('a -> 'b -> exn -> content Lwt.t) ->
  ('a -> 'b -> content Lwt.t) ->
  'a ->
  'b ->
  Html_types.html Eliom.Content.Html.elt Lwt.t
```
Default wrapper for service handler generating pages. It takes as parameter a function generating page content (body content) and transforms it into a function generating the whole page, according to the arguments given to the functor. Use the `predicate` function if you have something to check before the generation of the page. If `predicate` returns `false`, the page will be generated using the `fallback` function. The default fallback is the error page given as parameter to the functor. It is also used when the handler raises an exception. The error page is sent with an HTTP status matching the error: 403 when the user may not see the page ([`Session.Not_connected`](./Os-Session.md#exception-Not_connected), [`Session.Permission_denied`](./Os-Session.md#exception-Permission_denied), a predicate returning `false`), 404 when what it shows does not exist (`Not_found`, `Eliom.Common.Eliom_404`, `User.No_such_user`, `Db.No_such_user`, `Db.No_such_resource`, `Handlers.No_such_resource`) and 500 for any other exception; for `Predicate_failed (Some exc)`, the status of `exc`. No `WWW-Authenticate` challenge is sent, hence 403 rather than 401 for a visitor who is not connected. The fallback may set another status with `Eliom.Registration.set_status`.

```ocaml
module Opt : sig ... end
```
```ocaml
val connected_page : 
  ?allow:Types.Group.t list ->
  ?deny:Types.Group.t list ->
  ?predicate:(Types.User.id option -> 'a -> 'b -> bool Lwt.t) ->
  ?fallback:(Types.User.id option -> 'a -> 'b -> exn -> content Lwt.t) ->
  (Types.User.id -> 'a -> 'b -> content Lwt.t) ->
  'a ->
  'b ->
  Html_types.html Eliom.Content.Html.elt Lwt.t
```
Wrapper for pages that first checks if the user is connected. See [`Session.connected_fun`](./Os-Session.md#val-connected_fun). The error page gets an HTTP status, as with [`page`](./#val-page).
