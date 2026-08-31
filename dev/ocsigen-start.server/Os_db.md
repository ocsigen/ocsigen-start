# Module `Os_db`

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
```ocaml
exception No_such_resource
```
Exception raised when no resource corresponds to the database request.

```ocaml
exception Wrong_password
```
Exception raised when password do not match.

```ocaml
exception Password_not_set
```
Exception raised when user has no password.

```ocaml
exception No_such_user
```
Exception raised when users attempts to connect with unknown identifier.

```ocaml
exception Empty_password
```
Exception raised when user attempts to connect with empty password.

```ocaml
exception Main_email_removal_attempt
```
Exception raised when there is an attempt to remove the main email.

```ocaml
exception Account_not_activated
```
Exception raised when the account is not activated.

```ocaml
val pwd_crypt_ref : 
  ((string -> string) * (Os_types.User.id -> string -> string -> bool)) ref
```
`pwd_crypt_ref` is a reference to `(f_crypt, f_check)` where

- `f_crypt pwd` is used to encrypt the password `pwd`.
- `f_check userid pwd hashed_pwd` returns `true` if the hash of `pwd` and the hashed password `hashed_pwd` of the user with id `userid` match. If they don't match, it returns `false`.
```ocaml
module Email : sig ... end
```
This module is used for low-level email management with database.

```ocaml
module User : sig ... end
```
This module is used for low-level user management with database.

```ocaml
module Groups : sig ... end
```
This module is low-level and used to manage groups of user.

```ocaml
module Phone : sig ... end
```
Manage user phone numbers
