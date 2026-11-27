# Module `Current_user.Opt`

Instead of exception, the module `Opt` returns an option.

```ocaml
val get_current_user : unit -> Types.User.t option
```
`get_current_user ()` returns the current user as a `Types.User.t option` type. If no user is connected, `None` is returned.

```ocaml
val get_current_userid : unit -> Types.User.id option
```
`get_current_userid ()` returns the ID of the current user as an option. If no user is connected, `None` is returned.
