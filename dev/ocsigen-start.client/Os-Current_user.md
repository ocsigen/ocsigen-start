# Module `Os.Current_user`

This module provides functions and types to manage the current user.

On server side, this will work only if the current request in wrapped in [`Session.connected_wrapper`](./Os-Session.md#val-connected_wrapper), or [`Session.connected_fun`](./Os-Session.md#val-connected_fun), etc. Otherwise, an exception is raised.

```ocaml
type current_user = 
  | CU_idontknown
  | CU_notconnected
  | CU_user of Types.User.t
```
```ocaml
val get_current_user : unit -> Types.User.t
```
`get_current_user ()` returns the current user as a [`Types.User.t`](./Os-Types-User.md#type-t) type. If no user is connected, it fails with [`Session.Not_connected`](./Os-Session.md#exception-Not_connected).

```ocaml
val get_current_userid : unit -> Types.User.id
```
`get_current_userid ()` returns the ID of the current user. If no user is connected, it fails with [`Session.Not_connected`](./Os-Session.md#exception-Not_connected).

```ocaml
module Opt : sig ... end
```
Instead of exception, the module `Opt` returns an option.

```ocaml
val remove_email_from_user : string -> unit Lwt.t
```
`remove_email_from_user email` removes the email `email` of the current user. If no user is connected, it fails with [`Session.Not_connected`](./Os-Session.md#exception-Not_connected). If `email` is the main email of the current user, it fails with `Db.Main_email_removal_attempt`.

```ocaml
val update_main_email : string -> unit Lwt.t
```
`update_main_email email` sets the main email of the current user to `email`. If no user is connected, it fails with [`Session.Not_connected`](./Os-Session.md#exception-Not_connected).

```ocaml
val update_language : string -> unit Lwt.t
```
`update_language language` updates the language of the current user. If no user is connected, it fails with [`Session.Not_connected`](./Os-Session.md#exception-Not_connected).

```ocaml
val me : current_user ref
```
