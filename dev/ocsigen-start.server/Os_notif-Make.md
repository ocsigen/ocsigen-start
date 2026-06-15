
# Module `Os_notif.Make`

see `Eliom_notif.Make`


## Parameters

```ocaml
module A : ARG
```

## Signature

```ocaml
type identity = Os_types.User.id option
```
`identity` is the type of values used to differentiate one listener from another. Typically it will be a user, but it could also for instance be a chat window.

```ocaml
type key = A.key
```
`key` is the type of values designating a given resource.

```ocaml
type server_notif = A.server_notif
```
server notification type; Can be different from `client_notif`.

```ocaml
type client_notif = A.client_notif
```
client notification type; Can be different from `server_notif`.

```ocaml
val init : unit -> unit Lwt.t
```
Initialise the notification module for the current client. This function needs to be called before using most other functions of this module. It isn't called implicitly during module instantiation because it relies on identity data which might not be available yet.

```ocaml
val deinit : unit -> unit
```
Deinitialise/deactivate the notification module for the current client.

```ocaml
val listen : key -> unit
```
Make client process listen on data whose index is `key`

```ocaml
val unlisten : key -> unit
```
Stop listening on data `key`

```ocaml
module Ext : sig ... end
```
```ocaml
val client_ev : unit -> (key * client_notif) Eliom_react.Down.t
```
Returns the client react event.

`'a Eliom_react.Down.t` \= `'a React.E.t` on client side.

Map a function on this event to react to notifications from the server. For example:

let%client handle\_notification some\_stuff ev \= ...

let%server something some\_stuff \= ignore `%client (ignore (React.E.map (handle_notification ~%some_stuff) ~%(Notif_module.client_ev ()) ) : unit) `

```ocaml
val clean : unit -> unit
```
Call `clean ()` to clear the tables from empty data.

```ocaml
val unlisten_user : 
  ?sitedata:Eliom_common.sitedata ->
  userid:Os_types.User.id ->
  key ->
  unit
```
Make a user stop listening on data `key`. This function will work as expected without a value supplied for `sitedata` if called during a request or initialisation. Otherwise a value needs to be supplied.

```ocaml
val notify : 
  ?notfor:[ `Me | `User of Os_types.User.id ] ->
  key ->
  server_notif ->
  unit
```