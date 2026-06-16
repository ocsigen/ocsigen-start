
# Module `Os_core_db`

This module defines low level functions for database requests.

```ocaml
module PGOCaml : PGOCaml_generic.PGOCAML_GENERIC with type 'a monad = 'a Lwt.t
```
```ocaml
val init : 
  ?host:string ->
  ?port:int ->
  ?user:string ->
  ?password:string ->
  ?database:string ->
  ?unix_domain_socket_dir:string ->
  ?pool_size:int ->
  ?init:(PGOCaml.pa_pg_data PGOCaml.t -> unit Lwt.t) ->
  unit ->
  unit
```
`init ?host ?port ?user ?password ?database ?unix_domain_socket_dir ?init ()` initializes the variables for the database access and register a function `init` invoked each time a connection is created.

```ocaml
val full_transaction_block : 
  (PGOCaml.pa_pg_data PGOCaml.t -> 'a Lwt.t) ->
  'a Lwt.t
```
`full_transaction_block f` executes function `f` within a database transaction. The argument of `f` is a PGOCaml database handle.

```ocaml
val without_transaction : 
  (PGOCaml.pa_pg_data PGOCaml.t -> 'a Lwt.t) ->
  'a Lwt.t
```
`without_transaction f` executes function `f` outside a database transaction. The argument of `f` is a PGOCaml database handle.

```ocaml
val connection_pool : 
  unit ->
  PGOCaml.pa_pg_data PGOCaml.t Resource_pooling.Resource_pool.t
```
Direct access to the connection pool

```ocaml
type wrapper = {
  f : 'a. PGOCaml.pa_pg_data PGOCaml.t -> (unit -> 'a Lwt.t) -> 'a Lwt.t;
}
```
Setup a wrapper function which is used each time a connection is acquired. This function can perform some actions before and/or after the connection is used.

```ocaml
val set_connection_wrapper : wrapper -> unit
```