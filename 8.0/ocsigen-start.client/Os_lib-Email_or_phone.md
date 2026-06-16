
# Module `Os_lib.Email_or_phone`

Parse strings that can be e-mails or phones.

```ocaml
type t
```
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
type y = [ 
  | `Email
  | `Phone
 ]
```
```ocaml
val y : t -> y
```
```ocaml
val to_string : t -> string
```
```ocaml
val of_string : only_mail:bool -> string -> t option
```
```ocaml
module Almost : sig ... end
```
```ocaml
val of_almost : Almost.t -> t option
```