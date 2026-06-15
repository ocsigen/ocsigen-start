
# Module `Os_connect_phone`

```ocaml
type sms_error_core = [ 
  | `Unknown
  | `Send
  | `Limit
  | `Invalid_number
 ]
```
To be used for signalling errors with SMS transmission

```ocaml
val set_send_sms_handler : 
  (number:string -> string -> (unit, sms_error_core) result Lwt.t) ->
  unit
```
`set_send_sms_handler f` registers `f` as the function to be called to send SMS messages. Used to send activation codes for connectivity by mail.

```ocaml
val confirm_code_signup_no_connect : 
  first_name:string ->
  last_name:string ->
  code:string ->
  password:string ->
  unit ->
  Os_types.User.id option Lwt.t
```
Confirm validation code and create corresponding user.

```ocaml
val confirm_code : Os_types.User.id -> string -> bool Lwt.t
```
Confirm validation code and add extra phone to account of the given user

```ocaml
type sms_error = [ 
  | `Ownership
  | sms_error_core
 ]
```
```ocaml
val request_code : string -> (unit, sms_error) result Lwt.t
```
Send a validation code for a new e-mail address (corresponds to `confirm_code_signup` and `confirm_code_extra`).

```ocaml
val request_recovery_code : string -> (unit, sms_error) result Lwt.t
```
Send a validation code for recovering an existing address.

```ocaml
val confirm_code_extra : string -> bool Lwt.t
```
Confirm validation code and add extra phone to account of the currently connected user

```ocaml
val confirm_code_signup : 
  first_name:string ->
  last_name:string ->
  code:string ->
  password:string ->
  unit ->
  bool Lwt.t
```
Confirm validation code and complete sign-up with the phone number.

```ocaml
val confirm_code_recovery : string -> bool Lwt.t
```
Confirm validation code and recover account. We redirect to the settings page for setting a new password.

```ocaml
val connect : 
  keepmeloggedin:bool ->
  password:string ->
  string ->
  [ `Login_ok | `No_such_user | `Wrong_password | `Password_not_set ] Lwt.t
```