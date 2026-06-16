
# Module `Os_email`

Basic module for sending e-mail messages to users, using some local sendmail program.

```ocaml
val set_from_addr : (string * string) -> unit
```
`set_from_addr (sender_name, sender_email)` sets the email address used to send mail to `sender_email` and the sender name to `sender_name`.

```ocaml
val set_mailer : string -> unit
```
`set_mailer mailer` sets the name of the external `sendmail` program on your system, used by the default [`send`](./#val-send) function.

```ocaml
val get_mailer : unit -> string
```
`get_mailer ()` returns the name of mailer program.

```ocaml
exception Invalid_mailer of string
```
Exception raised if the mailer is invalid. You can raise an exception of this type in email sending function if you use [`set_send`](./#val-set_send).

```ocaml
val email_pattern : string
```
The pattern used to check the validity of an e-mail address.

```ocaml
val is_valid : string -> bool
```
`is_valid email` returns `true` if the e-mail address `email` is valid. Else it returns `false`.

```ocaml
val send : 
  ?url:string ->
  ?from_addr:(string * string) ->
  to_addrs:(string * string) list ->
  subject:string ->
  string list ->
  unit Lwt.t
```
Send an e-mail to `to_addrs` from `from_addr`. You have to define the `subject` of your email. The body of the email is a list of strings and each element of the list is automatically separated by a new line. Tuples used by `from_addr` and `to_addrs` is of the form `(name, email)`.

```ocaml
val set_send : 
  (?url:string ->
    from_addr:(string * string) ->
    to_addrs:(string * string) list ->
    subject:string ->
    string list ->
    unit Lwt.t) ->
  unit
```
Customize email sending function. See [`send`](./#val-send) for more details about the arguments.
