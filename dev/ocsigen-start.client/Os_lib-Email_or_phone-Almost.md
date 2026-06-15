
# Module `Email_or_phone.Almost`

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
  | `Almost_phone
  | `Almost_email
  | `Invalid
 ]
```
```ocaml
val y_of_json_with_tag : 
  Deriving_Json_lexer.lexbuf ->
  [ `NCst of int | `Cst of int ] ->
  y
```
```ocaml
val y_recognize : [ `NCst of int | `Cst of int ] -> bool
```
```ocaml
val y_of_json : Deriving_Json_lexer.lexbuf -> y
```
```ocaml
val y_to_json : Buffer.t -> y -> unit
```
```ocaml
val y_json : y Deriving_Json.t
```
```ocaml
val y : t -> y
```
```ocaml
val to_string : t -> string
```
```ocaml
val of_string : only_mail:bool -> string -> t
```