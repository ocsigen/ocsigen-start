
# Module `Os_handlers`

This module contains pre-defined handlers for connect, disconnect, sign up, add a new email, etc. Each handler has a corresponding service in [`Os_services`](./Os_services.md).

```ocaml
val connect_handler : unit -> ((string * string) * bool) -> unit Lwt.t
```
`connect_handler () ((login, password), keepMeLoggedIn)` connects the user with `login` and `password` and keeps the user logged in between different session if `keepMeLoggedIn` is set to `true`.

```ocaml
val disconnect_handler : ?main_page:bool -> unit -> unit -> unit Lwt.t
```
`disconnect_handler ?main_page () ()` disconnects the current user.

```ocaml
val sign_up_handler : unit -> string -> unit Lwt.t
```
`sign_up_handler () email` signes up an user with email `email`.

```ocaml
val add_email_handler : unit -> string -> unit Lwt.t
```
`add_email_handler () email` adds a new e-mail address for the current user and sends an activation link. Eliom reference `Os_user.user_already_exists` is set to `true` if the e-mail address already exists in database.

```ocaml
exception Custom_action_link of Os_types.Action_link_key.info * bool
```
Exception raised when something went wrong with an action link key. The action link key is given as parameter as a type `Os_types.actionlinkkey_info`.

```ocaml
exception Account_already_activated_unconnected of Os_types.Action_link_key.info
```
Exception raised when an account has been already activated and no user is connected.

```ocaml
exception Invalid_action_key of Os_types.Action_link_key.info
```
Exception raised when the key is oudated.

```ocaml
exception No_such_resource
```
Exception raised when the requested resource is not available.

```ocaml
val action_link_handler : 
  int64 option ->
  string ->
  unit ->
  'a Eliom_registration.application_content Eliom_registration.kind Lwt.t
```
`action_link_handler userid_o activation_key ()` is the handler for activation keys.

Depending on the error, [`No_such_resource`](./#exception-No_such_resource), [`Custom_action_link`](./#exception-Custom_action_link), [`Invalid_action_key`](./#exception-Invalid_action_key) or [`Account_already_activated_unconnected`](./#exception-Account_already_activated_unconnected) can be raised.

```ocaml
val confirm_code_signup_handler : 
  unit ->
  (string * (string * (string * string))) ->
  unit Lwt.t
```
`confirm_code_signup_handler () (first_name, (last_name, (pass, number)))` sends a verification code to `number`, displays a popup for confirming the code, and creates the account if all goes well.

```ocaml
val confirm_code_extra_handler : unit -> string -> unit Lwt.t
```
`confirm_code_extra_handler () number` is like `confirm_code_signup_handler` but for adding an additional number to the account. The new phone is added to the account.

```ocaml
val confirm_code_recovery_handler : unit -> string -> unit Lwt.t
```
`confirm_code_recovery_handler () number` is like `confirm_code_signup_handler` but for recovering a lost password. The user is redirected to the settings page for setting a new password.

```ocaml
val set_password_rpc : (string * string) -> unit Lwt.t
```
`set_password_rpc (password, confirmation_password)` is a RPC to `set_password`.

```ocaml
val restart : ?url:string -> unit -> unit
```
`restart ?url ()` restarts the client and redirects to the url `url`.
