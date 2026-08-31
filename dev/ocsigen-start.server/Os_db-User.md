# Module `Os_db.User`

This module is used for low-level user management with database.

```ocaml
exception Invalid_action_link_key of Os_types.User.id
```
```ocaml
val userid_of_email : string -> Os_types.User.id Lwt.t
```
`userid_of_email email` returns the userid of the user which has the email `email`.

```ocaml
val is_registered : string -> bool Lwt.t
```
`is_registered email` returns `true` if the email is already registered. Else, it returns `false`.

```ocaml
val is_email_validated : Os_types.User.id -> string -> bool Lwt.t
```
`is_email_validated userid email` returns `true` if `email` has been validated by the user with id `userid`.

```ocaml
val set_email_validated : Os_types.User.id -> string -> unit Lwt.t
```
`set_email_validated userid email` valids `email` for the user with id `userid`.

```ocaml
val add_actionlinkkey : 
  ?autoconnect:bool ->
  ?action:
    [< `AccountActivation
    | `Custom of string
    | `PasswordReset AccountActivation ] ->
  ?data:string ->
  ?validity:int64 ->
  ?expiry:CalendarLib.Calendar.t ->
  act_key:string ->
  userid:Os_types.User.id ->
  email:string ->
  unit ->
  unit Lwt.t
```
```ocaml
val add_preregister : string -> unit Lwt.t
```
`add_preregister email` preregisters `email` in the database.

```ocaml
val remove_preregister : string -> unit Lwt.t
```
`remove_preregister email` removes `email` from the database.

```ocaml
val is_preregistered : string -> bool Lwt.t
```
`is_preregistered email` returns `true` if `email` is already registered. Else, it returns `false`.

```ocaml
val all : ?limit:int64 -> unit -> string list Lwt.t
```
`all ?limit ()` get all email addresses with a limit of `limit` (default is 10\).

```ocaml
val create : 
  ?password:string ->
  ?avatar:string ->
  ?language:string ->
  ?email:string ->
  firstname:string ->
  lastname:string ->
  unit ->
  Os_types.User.id Lwt.t
```
`create ?password ?avatar ?language ~firstname ~lastname email` creates a new user in the database and returns the userid of the new user. Email, first name, last name and language are mandatory to create a new user. If `password` is passed as an empty string, it fails with the message `"empty password"`. TODO: change it to an exception?

```ocaml
val update : 
  ?password:string ->
  ?avatar:string ->
  ?language:string ->
  firstname:string ->
  lastname:string ->
  Os_types.User.id ->
  unit Lwt.t
```
`update ?password ?avatar ?language ~firstname ~lastname userid` updates the user profile with `userid`. If `password` is passed as an empty string, it fails with the message `"empty password"`. TODO: change it to an exception?

```ocaml
val update_password : userid:Os_types.User.id -> password:string -> unit Lwt.t
```
`update_password ~userid ~new_password` updates the password of the user with ID `userid`. If `password` is passed as an empty string, it fails with the message `"empty password"`. TODO: change it to an exception?

```ocaml
val update_avatar : userid:Os_types.User.id -> avatar:string -> unit Lwt.t
```
`update_avatar ~userid ~avatar` updates the avatar of the user with ID `userid`.

```ocaml
val update_main_email : userid:Os_types.User.id -> email:string -> unit Lwt.t
```
`update_main_email ~userid ~email` updates the main email of the user with ID `userid`.

```ocaml
val update_language : userid:Os_types.User.id -> language:string -> unit Lwt.t
```
`update_language ~userid ~language` updates the language of the user with ID `userid`.

```ocaml
val verify_password : email:string -> password:string -> Os_types.User.id Lwt.t
```
`verify_password ~email ~password` returns the userid if user with email `email` is registered with the password `password`. If `password` the password is wrong, it fails with exception [`Wrong_password`](./Os_db.md#exception-Wrong_password). If user exists but account is not validated, it fails with exception [`Account_not_activated`](./Os_db.md#exception-Account_not_activated). If user has no password, it fails with exception [`Password_not_set`](./Os_db.md#exception-Password_not_set). If user is not found, it fails with exception [`No_such_user`](./Os_db.md#exception-No_such_user). If password is empty, it fails with exception [`Empty_password`](./Os_db.md#exception-Empty_password).

```ocaml
val verify_password_phone : 
  number:string ->
  password:string ->
  Os_types.User.id Lwt.t
```
`verify_password_phone ~number ~password` returns the userid if user who owns `number` and whose password is `password`. If `password` the password is wrong, it fails with exception [`Wrong_password`](./Os_db.md#exception-Wrong_password). If user has no password, it fails with exception [`Password_not_set`](./Os_db.md#exception-Password_not_set). If user is not found, it fails with exception [`No_such_user`](./Os_db.md#exception-No_such_user). If password is empty, it fails with exception [`Empty_password`](./Os_db.md#exception-Empty_password).

```ocaml
val user_of_userid : 
  Os_types.User.id ->
  (Os_types.User.id * string * string * string option * bool * string option)
    Lwt.t
```
`user_of_userid userid` returns a tuple `(userid, firstname, lastname, avatar, bool_password, language)` describing the information about the user with ID `userid`. `bool_password` is a boolean. Its value is `true` if a password has been set. Else `false`. If there is no such user, it fails with [`No_such_resource`](./Os_db.md#exception-No_such_resource).

```ocaml
val get_actionlinkkey_info : string -> Os_types.Action_link_key.info Lwt.t
```
`get_actionlinkkey_info key` returns the information about the action link `key` as a type [`Os_types.Action_link_key.info`](./Os_types-Action_link_key.md#type-info).

```ocaml
val emails_of_userid : Os_types.User.id -> string list Lwt.t
```
`emails_of_userid userid` returns all emails registered for the user with ID `userid`. If there is no user with `userid` as ID, it fails with [`No_such_resource`](./Os_db.md#exception-No_such_resource).

```ocaml
val emails_of_userid_with_status : 
  Os_types.User.id ->
  (string * bool) list Lwt.t
```
Like `emails_of_userid`, but also returns validation status. This way we perform fewer DB queries.

```ocaml
val email_of_userid : Os_types.User.id -> string option Lwt.t
```
`email_of_userid userid` returns the main email registered for the user with ID `userid`. If there is no such user, it fails with [`No_such_resource`](./Os_db.md#exception-No_such_resource).

```ocaml
val is_main_email : userid:Os_types.User.id -> email:string -> bool Lwt.t
```
`is_main_email ~email ~userid` returns `true` if the main email of the user with ID `userid` is `email`. If there is no such user or if `email` is not the main email, it returns `false`.

```ocaml
val add_email_to_user : userid:Os_types.User.id -> email:string -> unit Lwt.t
```
`add_email_to_user ~userid ~email` add `email` to user with ID `userid`.

```ocaml
val remove_email_from_user : 
  userid:Os_types.User.id ->
  email:string ->
  unit Lwt.t
```
`remove_email_from_user ~userid ~email` removes the email `email` from the emails list of user with ID `userid`. If `email` is the main email, it fails with [`Main_email_removal_attempt`](./Os_db.md#exception-Main_email_removal_attempt).

```ocaml
val get_language : Os_types.User.id -> string option Lwt.t
```
`get_language userid` returns the language of the user with ID `userid`

```ocaml
val get_users : 
  ?pattern:string ->
  unit ->
  (Os_types.User.id * string * string * string option * bool * string option)
    list
    Lwt.t
```
`get_users ~pattern ()` returns all users matching the pattern `pattern` as a tuple `(userid, firstname, lastname, avatar, bool_password, language)`.
