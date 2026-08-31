# Module `Os_user_proxy`

```ocaml
val get_data : Os_types.User.id -> Os_types.User.t Lwt.t
```
`get_data userid` returns the user which has ID `userid`. For the moment, `myid_o` is not used but it will be use later.

Data comes from the database, not the cache.

```ocaml
val get_data_from_cache : Os_types.User.id -> Os_types.User.t Lwt.t
```
`get_data_from_cache userid` returns the user with ID `userid` saved in cache.
