# Module `Os_db.Email`

This module is used for low-level email management with database.

```ocaml
val available : string -> bool Lwt.t
```
`available email` returns `true` if `email` is not already used. Else, it returns `false`.
