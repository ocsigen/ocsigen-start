# Module `Os_types.User`

```ocaml
type id = int64
```
Type representing a user ID

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
  userid : id;
  fn : string;
  ln : string;
  avatar : string option;
  language : string option;
}
```
Type representing a user. See [`Os_user`](./Os_user.md).

```ocaml
val of_json : Deriving_Json_lexer.lexbuf -> t
```
```ocaml
val to_json : Buffer.t -> t -> unit
```
```ocaml
val json : t Deriving_Json.t
```
