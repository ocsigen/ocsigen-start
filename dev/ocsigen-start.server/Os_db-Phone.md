
# Module `Os_db.Phone`

Manage user phone numbers

```ocaml
val add : int64 -> string -> bool Lwt.t
```
`add userid number` associates `number` with the user `userid`. Returns `true` on success.

```ocaml
val exists : string -> bool Lwt.t
```
Does the number exist in the database?

```ocaml
val userid : string -> Os_types.User.id option Lwt.t
```
The user corresponding to a phone number (if any).

```ocaml
val delete : int64 -> string -> unit Lwt.t
```
`delete userid number` deletes `number`, which has to be associated to `userid`.

```ocaml
val get_list : int64 -> string list Lwt.t
```
`get_list userid` returns the list of number associated to the user.
