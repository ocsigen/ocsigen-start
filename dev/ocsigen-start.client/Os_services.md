
# Module `Os_services`

```ocaml
val main_service : 
  (unit,
    unit,
    Eliom_service.get,
    Eliom_service.att,
    Eliom_service.non_co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    unit,
    unit,
    Eliom_service.non_ocaml)
    Eliom_service.t
```
The main service.

```ocaml
val preregister_service : 
  (unit,
    string,
    Eliom_service.post,
    Eliom_service.non_att,
    Eliom_service.co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom_parameter.param_name,
    Eliom_service.non_ocaml)
    Eliom_service.t
```
A POST service to preregister a user. By default, an email is enough.

```ocaml
val forgot_password_service : 
  (unit,
    string,
    Eliom_service.post,
    Eliom_service.non_att,
    Eliom_service.co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom_parameter.param_name,
    Eliom_service.non_ocaml)
    Eliom_service.t
```
A POST service when the user forgot his password. See `Os_handlers.forgot_password_handler` for a default handler.

```ocaml
val set_personal_data_service : 
  (unit,
    (string * string) * (string * string),
    Eliom_service.post,
    Eliom_service.non_att,
    Eliom_service.co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    unit,
    ([ `One of string ] Eliom_parameter.param_name
     * [ `One of string ] Eliom_parameter.param_name)
    * ([ `One of string ] Eliom_parameter.param_name
       * [ `One of string ] Eliom_parameter.param_name),
    Eliom_service.non_ocaml)
    Eliom_service.t
```
A POST service to update the basic user data like first name, last name and password. See `Os_handlers.set_personal_data_handler'` for a default handler.

```ocaml
val sign_up_service : 
  (unit,
    string,
    Eliom_service.post,
    Eliom_service.non_att,
    Eliom_service.co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom_parameter.param_name,
    Eliom_service.non_ocaml)
    Eliom_service.t
```
A POST service to sign up with only an email address. See [`Os_handlers.sign_up_handler`](./Os_handlers.md#val-sign_up_handler) for a default handler.

```ocaml
val connect_service : 
  (unit,
    (string * string) * bool,
    Eliom_service.post,
    Eliom_service.non_att,
    Eliom_service.co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    unit,
    ([ `One of string ] Eliom_parameter.param_name
     * [ `One of string ] Eliom_parameter.param_name)
    * [ `One of bool ] Eliom_parameter.param_name,
    Eliom_service.non_ocaml)
    Eliom_service.t
```
A POST service to connect a user with username and password. See [`Os_handlers.connect_handler`](./Os_handlers.md#val-connect_handler) for a default handler.

```ocaml
val disconnect_service : 
  (unit,
    unit,
    Eliom_service.post,
    Eliom_service.non_att,
    Eliom_service.co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    unit,
    unit,
    Eliom_service.non_ocaml)
    Eliom_service.t
```
A POST service to disconnect the current user. See [`Os_handlers.disconnect_handler`](./Os_handlers.md#val-disconnect_handler) for a default handler.

```ocaml
val action_link_service : 
  (string,
    unit,
    Eliom_service.get,
    Eliom_service.non_att,
    Eliom_service.co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    [ `One of string ] Eliom_parameter.param_name,
    unit,
    Eliom_service.non_ocaml)
    Eliom_service.t
```
A GET service for action link keys. See [`Os_handlers.action_link_handler`](./Os_handlers.md#val-action_link_handler) for a default handler and `Os_db.action_link_table` for more information about the action process.

```ocaml
val set_password_service : 
  (unit,
    string * string,
    Eliom_service.post,
    Eliom_service.non_att,
    Eliom_service.co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom_parameter.param_name
    * [ `One of string ] Eliom_parameter.param_name,
    Eliom_service.non_ocaml)
    Eliom_service.t
```
A POST service to update the password. An update password action is associated with the confirmation password. See `Os_handlers.set_password_handler'` for a default handler.

```ocaml
val add_email_service : 
  (unit,
    string,
    Eliom_service.post,
    Eliom_service.non_att,
    Eliom_service.co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom_parameter.param_name,
    Eliom_service.non_ocaml)
    Eliom_service.t
```
A POST service to add an email to a user. See [`Os_handlers.add_email_handler`](./Os_handlers.md#val-add_email_handler) for a default handler.

```ocaml
val update_language_service : 
  (unit,
    string,
    Eliom_service.post,
    Eliom_service.non_att,
    Eliom_service.co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom_parameter.param_name,
    Eliom_service.non_ocaml)
    Eliom_service.t
```
A POST service to update the language of the current user. See `Os_handlers.update_language_handler` for a default handler.

```ocaml
val confirm_code_signup_service : 
  (unit,
    string * (string * (string * string)),
    Eliom_service.post,
    Eliom_service.non_att,
    Eliom_service.co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom_parameter.param_name
    * ([ `One of string ] Eliom_parameter.param_name
       * ([ `One of string ] Eliom_parameter.param_name
          * [ `One of string ] Eliom_parameter.param_name)),
    Eliom_service.non_ocaml)
    Eliom_service.t
```
Confirm SMS activation code and (if valid) register new user.

```ocaml
val confirm_code_extra_service : 
  (unit,
    string,
    Eliom_service.post,
    Eliom_service.non_att,
    Eliom_service.co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom_parameter.param_name,
    Eliom_service.non_ocaml)
    Eliom_service.t
```
Confirm SMS activation code and (if valid) add new phone number to user's account.

```ocaml
val confirm_code_recovery_service : 
  (unit,
    string,
    Eliom_service.post,
    Eliom_service.non_att,
    Eliom_service.co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom_parameter.param_name,
    Eliom_service.non_ocaml)
    Eliom_service.t
```
Confirm SMS activation code and (if valid) allow the user to set a new password.

```ocaml
val confirm_code_remind_service : 
  (unit,
    string,
    Eliom_service.post,
    Eliom_service.non_att,
    Eliom_service.co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom_parameter.param_name,
    Eliom_service.non_ocaml)
    Eliom_service.t
```
Temporary alternate name for `confirm_code_recovery_handler` to facilite the transition.

```ocaml
val register_settings_service : 
  (unit,
    unit,
    Eliom_service.get,
    Eliom_service.att,
    Eliom_service.non_co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    unit,
    unit,
    Eliom_service.non_ocaml)
    Eliom_service.t ->
  unit
```
Register the settings service (defined in the app rather than in the OS lib) because we need to perform redirections to it.
