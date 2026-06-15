
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
val forgot_password_handler : 
  (unit,
    unit,
    Eliom_service.get,
    Eliom_service.att,
    _,
    Eliom_service.non_ext,
    _,
    _,
    unit,
    unit,
    'c)
    Eliom_service.t ->
  unit ->
  string ->
  unit Lwt.t
```
`forgot_password_handler service () email` creates and sends an action link to `email` if the user forgot his password and redirects to `service`. If `email` doesn't correspond to any user, [`Os_user.user_does_not_exist`](./Os_user.md#val-user_does_not_exist) is set to `true` and [`Os_msg.msg`](./Os_msg.md#val-msg) is called with the level ``Err`.

```ocaml
val preregister_handler : unit -> string -> unit Lwt.t
```
`preregister_handler () email` preregisters the email `email`.

```ocaml
val set_password_handler : 
  Os_types.User.id ->
  unit ->
  (string * string) ->
  unit Lwt.t
```
`set_password_handler userid () (password, confirmation_password)` updates the password of the user with ID `userid` with the hashed value of `password` if `confirmation_password` corresponds to `password`. If they don't correspond, [`Os_msg.msg`](./Os_msg.md#val-msg) is called with the level ``Err`.

```ocaml
val set_personal_data_handler : 
  Os_types.User.id ->
  unit ->
  ((string * string) * (string * string)) ->
  unit Lwt.t
```
`set_personal_data_handler userid () ((firstname, lastname), (password, confirmation_password))` sets the corresponding data to given values.
