# Module `Os_user_proxy`

This module implements a cache of user using [`Eliom_cscache`](./../../eliom/eliom.server/Eliom_cscache.md) which allows to keep synchronized the cache between the client and the server. Even if there is a cache implemented in [`Os_user`](./Os_user.md) to avoid to do database requests, this last one is implementing only server side. Same for [`Os_request_cache`](./Os_request_cache.md) which is also only server-side.

```ocaml
val cache : (Os_types.User.id, Os_types.User.t) Eliom_cscache.t
```
Cache keeping userid and user information as a `Os_types.user` type.

```ocaml
val get_data_from_db : 'a -> Os_types.User.id -> Os_types.User.t Lwt.t
```
`get_data_from_db myid_o userid` returns the user which has ID `userid`. For the moment, `myid_o` is not used but it will be use later.

Data comes from the database, not the cache.

```ocaml
val get_data_from_db_for_client : 
  'a ->
  Os_types.User.id ->
  Os_types.User.t Lwt.t
```
`get_data_from_db_for_client myid_o userid` returns the user which has ID `userid`. For the moment, `myid_o` is not used but it will be use later.

Data comes from the database, not the cache.

```ocaml
val get_data : Os_types.User.id -> Os_types.User.t Lwt.t
```
`get_data userid` returns the user which has ID `userid`. For the moment, `myid_o` is not used but it will be use later.

Data comes from the database, not the cache.

```ocaml
val get_data_from_cache : Os_types.User.id -> Os_types.User.t Lwt.t
```
`get_data_from_cache userid` returns the user with ID `userid` saved in cache.
