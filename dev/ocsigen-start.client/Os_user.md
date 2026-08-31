# Module `Os_user`

```ocaml
type id = Os_types.User.id
```
Type alias to [`Os_types.User.id`](./Os_types-User.md#type-id) to allow to use `Os_user.id`.

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
type t = Os_types.User.t = {
  userid : id;
  fn : string;
  ln : string;
  avatar : string option;
  language : string option;
}
```
Type alias to [`Os_types.User.t`](./Os_types-User.md#type-t) to allow to use `Os_user.t`.

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
val userid_of_user : Os_types.User.t -> Os_types.User.id
```
`userid_of_user user` returns the userid of the user `user`.

```ocaml
val firstname_of_user : Os_types.User.t -> string
```
`firstname_of_user user` returns the first name of the user `user`

```ocaml
val lastname_of_user : Os_types.User.t -> string
```
`lastname_of_user user` returns the last name of the user `user`

```ocaml
val avatar_of_user : Os_types.User.t -> string option
```
`avatar_of_user user` returns the avatar of the user `user` as `Some avatar_uri`. It returns `None` if the user `user` has no avatar.

```ocaml
val avatar_uri_of_avatar : 
  ?absolute_path:bool ->
  string ->
  Eliom_content.Xml.uri
```
`avatar_uri_of_avatar ?absolute_path avatar` returns the URI (absolute or relative) depending on the value of `absolute_path`) of the avatar `avatar`.

```ocaml
val avatar_uri_of_user : 
  ?absolute_path:bool ->
  Os_types.User.t ->
  Eliom_content.Xml.uri option
```
`avatar_uri_of_user user` returns the avatar URI (absolute or relative) depending on the value of `absolute_path`) of the avatar of the user `user`. It returns `None` is the user `user` has no avatar.

```ocaml
val language_of_user : Os_types.User.t -> string option
```
`language_of_user user` returns the language of the user `user`

```ocaml
val fullname_of_user : Os_types.User.t -> string
```
Retrieve the full name of user (which is the concatenation of the first name and last name).

```ocaml
val is_complete : Os_types.User.t -> bool
```
`is_complete user` returns `true` if the first name and the last name of `Os_types.user` have been completed yet.
