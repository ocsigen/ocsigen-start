
# Module `Os_lib`

This module aims to provide common utilities functions.

```ocaml
module Email_or_phone : sig ... end
```
Parse strings that can be e-mails or phones.

```ocaml
val phone_regexp : Re.Str.regexp
```
```ocaml
val email_regexp : Re.Str.regexp
```
```ocaml
val memoizator : (unit -> 'a Lwt.t) -> unit -> 'a Lwt.t
```
`memoizator f ()` caches the returned value of `f ()`

```ocaml
val string_repeat : string -> int -> string
```
```ocaml
val string_filter : (char -> bool) -> string -> string
```
```ocaml
val lwt_bound_input_enter : 
  ?a:[< Html_types.input_attrib ] Eliom_content.Html.attrib list ->
  ?button:[< `Button | `Input ] Eliom_content.Html.elt ->
  ?validate:(string -> bool) Eliom_client_value.t ->
  (string -> unit Lwt.t) Eliom_client_value.t ->
  [> `Input ] Eliom_content.Html.elt
```
`lwt_bound_input_enter f` produces an input element bound to `f`, i.e., when the user submits the input, we call `f`.

```ocaml
val lwt_bind_input_enter : 
  ?validate:(string -> bool) Eliom_client_value.t ->
  ?button:[< `Button | `Input ] Eliom_content.Html.elt ->
  [ `Input ] Eliom_content.Html.elt ->
  (string -> unit Lwt.t) Eliom_client_value.t ->
  unit
```
`lwt_bound_input_enter inp f` calls f whenever the user submits the contents of `inp`.

```ocaml
module Http : sig ... end
```
This module contains functions about HTTP request.
