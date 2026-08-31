# Module `Os_current_user.Opt`

Instead of exception, the module `Opt` returns an option.

```ocaml
val get_current_user : unit -> Os_types.User.t option
```
`get_current_user ()` returns the current user as a `Os_types.User.t option` type. If no user is connected, `None` is returned.

```ocaml
val get_current_userid : unit -> Os_types.User.id option
```
`get_current_userid ()` returns the ID of the current user as an option. If no user is connected, `None` is returned.
