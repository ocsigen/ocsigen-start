
# Module `Os_types.Group`

```ocaml
type id = int64
```
Type representing a group ID

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
type t = {
  id : id;
  name : string;
  desc : string option;
}
```
Type representing a group. See [`Os_group`](./Os_group.md)
