
# Module `Os_current_user`

This module provides functions and types to manage the current user.

On server side, this will work only if the current request in wrapped in [`Os_session.connected_wrapper`](./../ocsigen-start.server/Os_session.md#val-connected_wrapper), or [`Os_session.connected_fun`](./../ocsigen-start.server/Os_session.md#val-connected_fun), etc. Otherwise, an exception is raised.

```ocaml
type current_user = 
  | CU_idontknown
  | CU_notconnected
  | CU_user of Os_types.User.t
```
```ocaml
val get_current_user : unit -> Os_types.User.t
```
`get_current_user ()` returns the current user as a [`Os_types.User.t`](./../ocsigen-start.server/Os_types-User.md#type-t) type. If no user is connected, it fails with [`Os_session.Not_connected`](./../ocsigen-start.server/Os_session.md#exception-Not_connected).

```ocaml
val get_current_userid : unit -> Os_types.User.id
```
`get_current_userid ()` returns the ID of the current user. If no user is connected, it fails with [`Os_session.Not_connected`](./../ocsigen-start.server/Os_session.md#exception-Not_connected).

```ocaml
module Opt : sig ... end
```
Instead of exception, the module `Opt` returns an option.

```ocaml
val remove_email_from_user : string -> unit Lwt.t
```
`remove_email_from_user email` removes the email `email` of the current user. If no user is connected, it fails with [`Os_session.Not_connected`](./../ocsigen-start.server/Os_session.md#exception-Not_connected). If `email` is the main email of the current user, it fails with [`Os_db.Main_email_removal_attempt`](./../ocsigen-start.server/Os_db.md#exception-Main_email_removal_attempt).

```ocaml
val update_main_email : string -> unit Lwt.t
```
`update_main_email email` sets the main email of the current user to `email`. If no user is connected, it fails with [`Os_session.Not_connected`](./../ocsigen-start.server/Os_session.md#exception-Not_connected).

```ocaml
val update_language : string -> unit Lwt.t
```
`update_language language` updates the language of the current user. If no user is connected, it fails with [`Os_session.Not_connected`](./../ocsigen-start.server/Os_session.md#exception-Not_connected).

```ocaml
val me : current_user ref
```