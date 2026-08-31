# Module `Os_group`

Groups of users. Groups are sets of users. Groups and group members are saved in database. Groups are used by OS for example to restrict access to pages or server functions.

```ocaml
exception No_such_group
```
Exception raised when no there is no group corresponding to the request (for example wrong ID or name).

```ocaml
type id = Os_types.Group.id
```
Type alias to [`Os_types.Group.id`](./Os_types-Group.md#type-id) to allow to use `Os_group.id`.

```ocaml
val id_of_json : Deriving_Json_lexer.lexbuf -> id
```
```ocaml
val id_to_json : Buffer.t -> id -> unit
```
```ocaml
val id_json : id Deriving_Json.t
```
```ocaml
type t = Os_types.Group.t = {
  id : id;
  name : string;
  desc : string option;
}
```
Type alias to [`Os_types.Group.t`](./Os_types-Group.md#type-t) to allow to use `Os_group.t`.

```ocaml
val of_json : Deriving_Json_lexer.lexbuf -> t
```
```ocaml
val to_json : Buffer.t -> t -> unit
```
```ocaml
val json : t Deriving_Json.t
```
```ocaml
val id_of_group : Os_types.Group.t -> Os_types.Group.id
```
`id_of_group group` returns the group ID.

```ocaml
val name_of_group : Os_types.Group.t -> string
```
`name_of_group group` returns the group name.

```ocaml
val desc_of_group : Os_types.Group.t -> string option
```
`desc_of_group group` returns the group description.

```ocaml
val create : ?description:string -> string -> Os_types.Group.t Lwt.t
```
`create ~description name` creates a new group in the database and returns it as a record of type `Os_types.Group.t`.

```ocaml
val group_of_name : string -> Os_types.Group.t Lwt.t
```
Overwrites the function `group_of_name` of `Os_db.Group` and use the `get` function of the cache module.

```ocaml
val add_user_in_group : 
  group:Os_types.Group.t ->
  userid:Os_types.User.id ->
  unit Lwt.t
```
`add_user_in_group ~group ~userid` adds the user with ID `userid` to `group`.

```ocaml
val remove_user_in_group : 
  group:Os_types.Group.t ->
  userid:Os_types.User.id ->
  unit Lwt.t
```
`remove_user_in_group ~group ~userid` removes the user with ID `userid` from `group`.

```ocaml
val in_group : 
  ?dbh:Os_db.PGOCaml.pa_pg_data Os_db.PGOCaml.t ->
  group:Os_types.Group.t ->
  userid:Os_types.User.id ->
  unit ->
  bool Lwt.t
```
`in_group ~group ~userid` returns `true` if the user with ID `userid` is in `group`.

```ocaml
val all : unit -> Os_types.Group.t list Lwt.t
```
`all ()` returns all the groups of the database.
