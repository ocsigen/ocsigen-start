# Module `Os.Services`

```ocaml
val main_service : 
  (unit,
    unit,
    Eliom.Service.get,
    Eliom.Service.att,
    Eliom.Service.non_co,
    Eliom.Service.non_ext,
    Eliom.Service.reg,
    [ `WithoutSuffix ],
    unit,
    unit,
    Eliom.Service.non_ocaml)
    Eliom.Service.t
```
The main service.

```ocaml
val preregister_service : 
  (unit,
    string,
    Eliom.Service.post,
    Eliom.Service.non_att,
    Eliom.Service.co,
    Eliom.Service.non_ext,
    Eliom.Service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom.Parameter.param_name,
    Eliom.Service.non_ocaml)
    Eliom.Service.t
```
A POST service to preregister a user. By default, an email is enough.

```ocaml
val forgot_password_service : 
  (unit,
    string,
    Eliom.Service.post,
    Eliom.Service.non_att,
    Eliom.Service.co,
    Eliom.Service.non_ext,
    Eliom.Service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom.Parameter.param_name,
    Eliom.Service.non_ocaml)
    Eliom.Service.t
```
A POST service when the user forgot his password. See [`Handlers.forgot_password_handler`](./Os-Handlers.md#val-forgot_password_handler) for a default handler.

```ocaml
val set_personal_data_service : 
  (unit,
    (string * string) * (string * string),
    Eliom.Service.post,
    Eliom.Service.non_att,
    Eliom.Service.co,
    Eliom.Service.non_ext,
    Eliom.Service.reg,
    [ `WithoutSuffix ],
    unit,
    ([ `One of string ] Eliom.Parameter.param_name
     * [ `One of string ] Eliom.Parameter.param_name)
    * ([ `One of string ] Eliom.Parameter.param_name
       * [ `One of string ] Eliom.Parameter.param_name),
    Eliom.Service.non_ocaml)
    Eliom.Service.t
```
A POST service to update the basic user data like first name, last name and password. See `Handlers.set_personal_data_handler'` for a default handler.

```ocaml
val sign_up_service : 
  (unit,
    string,
    Eliom.Service.post,
    Eliom.Service.non_att,
    Eliom.Service.co,
    Eliom.Service.non_ext,
    Eliom.Service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom.Parameter.param_name,
    Eliom.Service.non_ocaml)
    Eliom.Service.t
```
A POST service to sign up with only an email address. See [`Handlers.sign_up_handler`](./Os-Handlers.md#val-sign_up_handler) for a default handler.

```ocaml
val connect_service : 
  (unit,
    (string * string) * bool,
    Eliom.Service.post,
    Eliom.Service.non_att,
    Eliom.Service.co,
    Eliom.Service.non_ext,
    Eliom.Service.reg,
    [ `WithoutSuffix ],
    unit,
    ([ `One of string ] Eliom.Parameter.param_name
     * [ `One of string ] Eliom.Parameter.param_name)
    * [ `One of bool ] Eliom.Parameter.param_name,
    Eliom.Service.non_ocaml)
    Eliom.Service.t
```
A POST service to connect a user with username and password. See [`Handlers.connect_handler`](./Os-Handlers.md#val-connect_handler) for a default handler.

```ocaml
val disconnect_service : 
  (unit,
    unit,
    Eliom.Service.post,
    Eliom.Service.non_att,
    Eliom.Service.co,
    Eliom.Service.non_ext,
    Eliom.Service.reg,
    [ `WithoutSuffix ],
    unit,
    unit,
    Eliom.Service.non_ocaml)
    Eliom.Service.t
```
A POST service to disconnect the current user. See [`Handlers.disconnect_handler`](./Os-Handlers.md#val-disconnect_handler) for a default handler.

```ocaml
val action_link_service : 
  (string,
    unit,
    Eliom.Service.get,
    Eliom.Service.non_att,
    Eliom.Service.co,
    Eliom.Service.non_ext,
    Eliom.Service.reg,
    [ `WithoutSuffix ],
    [ `One of string ] Eliom.Parameter.param_name,
    unit,
    Eliom.Service.non_ocaml)
    Eliom.Service.t
```
A GET service for action link keys. See [`Handlers.action_link_handler`](./Os-Handlers.md#val-action_link_handler) for a default handler and `Db.action_link_table` for more information about the action process.

```ocaml
val set_password_service : 
  (unit,
    string * string,
    Eliom.Service.post,
    Eliom.Service.non_att,
    Eliom.Service.co,
    Eliom.Service.non_ext,
    Eliom.Service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom.Parameter.param_name
    * [ `One of string ] Eliom.Parameter.param_name,
    Eliom.Service.non_ocaml)
    Eliom.Service.t
```
A POST service to update the password. An update password action is associated with the confirmation password. See `Handlers.set_password_handler'` for a default handler.

```ocaml
val add_email_service : 
  (unit,
    string,
    Eliom.Service.post,
    Eliom.Service.non_att,
    Eliom.Service.co,
    Eliom.Service.non_ext,
    Eliom.Service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom.Parameter.param_name,
    Eliom.Service.non_ocaml)
    Eliom.Service.t
```
A POST service to add an email to a user. See [`Handlers.add_email_handler`](./Os-Handlers.md#val-add_email_handler) for a default handler.

```ocaml
val update_language_service : 
  (unit,
    string,
    Eliom.Service.post,
    Eliom.Service.non_att,
    Eliom.Service.co,
    Eliom.Service.non_ext,
    Eliom.Service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom.Parameter.param_name,
    Eliom.Service.non_ocaml)
    Eliom.Service.t
```
A POST service to update the language of the current user. See `Handlers.update_language_handler` for a default handler.

```ocaml
val confirm_code_signup_service : 
  (unit,
    string * (string * (string * string)),
    Eliom.Service.post,
    Eliom.Service.non_att,
    Eliom.Service.co,
    Eliom.Service.non_ext,
    Eliom.Service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom.Parameter.param_name
    * ([ `One of string ] Eliom.Parameter.param_name
       * ([ `One of string ] Eliom.Parameter.param_name
          * [ `One of string ] Eliom.Parameter.param_name)),
    Eliom.Service.non_ocaml)
    Eliom.Service.t
```
Confirm SMS activation code and (if valid) register new user.

```ocaml
val confirm_code_extra_service : 
  (unit,
    string,
    Eliom.Service.post,
    Eliom.Service.non_att,
    Eliom.Service.co,
    Eliom.Service.non_ext,
    Eliom.Service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom.Parameter.param_name,
    Eliom.Service.non_ocaml)
    Eliom.Service.t
```
Confirm SMS activation code and (if valid) add new phone number to user's account.

```ocaml
val confirm_code_recovery_service : 
  (unit,
    string,
    Eliom.Service.post,
    Eliom.Service.non_att,
    Eliom.Service.co,
    Eliom.Service.non_ext,
    Eliom.Service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom.Parameter.param_name,
    Eliom.Service.non_ocaml)
    Eliom.Service.t
```
Confirm SMS activation code and (if valid) allow the user to set a new password.

```ocaml
val confirm_code_remind_service : 
  (unit,
    string,
    Eliom.Service.post,
    Eliom.Service.non_att,
    Eliom.Service.co,
    Eliom.Service.non_ext,
    Eliom.Service.reg,
    [ `WithoutSuffix ],
    unit,
    [ `One of string ] Eliom.Parameter.param_name,
    Eliom.Service.non_ocaml)
    Eliom.Service.t
```
Temporary alternate name for `confirm_code_recovery_handler` to facilite the transition.

```ocaml
val register_settings_service : 
  (unit,
    unit,
    Eliom.Service.get,
    Eliom.Service.att,
    Eliom.Service.non_co,
    Eliom.Service.non_ext,
    Eliom.Service.reg,
    [ `WithoutSuffix ],
    unit,
    unit,
    Eliom.Service.non_ocaml)
    Eliom.Service.t ->
  unit
```
Register the settings service (defined in the app rather than in the OS lib) because we need to perform redirections to it.
