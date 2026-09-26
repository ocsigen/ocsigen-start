# Module `Os.User_proxy`

This module implements a cache of user using [`Eliom.Cscache`](./../../eliom/eliom.server/Eliom-Cscache.md) which allows to keep synchronized the cache between the client and the server. Even if there is a cache implemented in [`User`](./Os-User.md) to avoid to do database requests, this last one is implementing only server side. Same for [`Request_cache`](./Os-Request_cache.md) which is also only server-side.

```ocaml
val cache : (Types.User.id, Types.User.t) Eliom.Cscache.t
```
Cache keeping userid and user information as a `Types.user` type.

```ocaml
val get_data_from_db : 'a -> Types.User.id -> Types.User.t Lwt.t
```
`get_data_from_db myid_o userid` returns the user which has ID `userid`. For the moment, `myid_o` is not used but it will be use later.

Data comes from the database, not the cache.

```ocaml
val get_data_from_db_for_client : 'a -> Types.User.id -> Types.User.t Lwt.t
```
`get_data_from_db_for_client myid_o userid` returns the user which has ID `userid`. For the moment, `myid_o` is not used but it will be use later.

Data comes from the database, not the cache.

```ocaml
val get_data : Types.User.id -> Types.User.t Lwt.t
```
`get_data userid` returns the user which has ID `userid`. For the moment, `myid_o` is not used but it will be use later.

Data comes from the database, not the cache.

```ocaml
val get_data_from_cache : Types.User.id -> Types.User.t Lwt.t
```
`get_data_from_cache userid` returns the user with ID `userid` saved in cache.
