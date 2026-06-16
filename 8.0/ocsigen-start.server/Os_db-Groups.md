
# Module `Os_db.Groups`

This module is low-level and used to manage groups of user.

```ocaml
val create : ?description:string -> string -> unit Lwt.t
```
`create ?description name` creates a new group with name `name` and with description `description`.

```ocaml
val group_of_name : 
  string ->
  (Os_types.Group.id * string * string option) Lwt.t
```
`group_of_name name` returns a tuple `(groupid, name, description)` describing the group. If no group has the name `name`, it fails with [`No_such_resource`](./Os_db.md#exception-No_such_resource).

```ocaml
val add_user_in_group : 
  groupid:Os_types.Group.id ->
  userid:Os_types.User.id ->
  unit Lwt.t
```
`add_user_in_group ~groupid ~userid` adds the user with ID `userid` in the group with ID `groupid`

```ocaml
val remove_user_in_group : 
  groupid:Os_types.Group.id ->
  userid:Os_types.User.id ->
  unit Lwt.t
```
`remove_user_in_group ~groupid ~userid` removes the user with ID `userid` in the group with ID `groupid`

```ocaml
val in_group : 
  ?dbh:PGOCaml.pa_pg_data PGOCaml.t ->
  groupid:Os_types.Group.id ->
  userid:Os_types.User.id ->
  unit ->
  bool Lwt.t
```
`in_group ~groupid ~userid` returns `true` if the user with ID `userid` is in the group with ID `groupid`.

```ocaml
val all : unit -> (Os_types.Group.id * string * string option) list Lwt.t
```
`all ()` returns all groups as list of tuple `(groupid, name, description)`.
