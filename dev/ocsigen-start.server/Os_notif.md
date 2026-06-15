
# Module `Os_notif`

Server to client notifications.

This module is a version of `Eliom_notif` that fixes the types `identity` of `Eliom_notif.S` to `Os_types.User.id option` (`option` so that users can be notified that are not logged in). It takes care of (de)initialisation so `init` and `deinit` need not be called anymore. Also it adds a specialised version of `unlisten_user`.

```ocaml
module type S = sig ... end
```
```ocaml
module type ARG = sig ... end
```
`ARG` is for making `Make`. It is a simplified version of `Eliom_notif.ARG`.

```ocaml
module Make
  (A : ARG) : 
  S
    with type key = A.key
     and type server_notif = A.server_notif
     and type client_notif = A.client_notif
```
see `Eliom_notif.Make`

```ocaml
module type ARG_SIMPLE = sig ... end
```
`ARG_SIMPLE` is for making `Make_Simple`. It is a simplified version of `Eliom_notif.ARG_SIMPLE`

```ocaml
module Make_Simple
  (A : ARG_SIMPLE) : 
  S
    with type key = A.key
     and type server_notif = A.notification
     and type client_notif = A.notification
```
Use this functor in case messages are to be delivered only to clients connected to the current server, as is always the case in a single-server set-up.
