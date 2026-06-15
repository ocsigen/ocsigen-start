
# Module `Os_user`

This module provides functions and types about users.

```ocaml
type id = Os_types.User.id
```
Type alias to [`Os_types.User.id`](./Os_types-User.md#type-id) to allow to use `Os_user.id`.

```ocaml
val id_of_json : Deriving_Json_lexer.lexbuf -> id
```
```ocaml
val id_to_json : Buffer.t -> id -> unit
```
```ocaml
val id_json : id Deriving_Json.t
```
```ocaml
type t = Os_types.User.t = {
  userid : id;
  fn : string;
  ln : string;
  avatar : string option;
  language : string option;
}
```
Type alias to [`Os_types.User.t`](./Os_types-User.md#type-t) to allow to use `Os_user.t`.

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
exception Already_exists of Os_types.User.id
```
Exception used if an user already exists. The parameter is the userid of the existing user.

```ocaml
exception No_such_user
```
Exception used if an user doesn't exist.

```ocaml
val password_set : Os_types.User.id -> bool Lwt.t
```
`password_set userid` returns `true` if the user with ID `userid` has set a password. Else `false`.

```ocaml
val wrong_password : bool Eliom_reference.Volatile.eref
```
Reference used to remember if a wrong password has been already typed.

```ocaml
val no_such_user : bool Eliom_reference.Volatile.eref
```
Reference used to remember if a wrong user has already been typed.

```ocaml
val account_not_activated : bool Eliom_reference.Volatile.eref
```
Reference used to remember if the account is activated.

```ocaml
val user_already_exists : bool Eliom_reference.Volatile.eref
```
Reference used to remember if the user already exists.

```ocaml
val user_does_not_exist : bool Eliom_reference.Volatile.eref
```
Reference used to remember if the user exists.

```ocaml
val user_already_preregistered : bool Eliom_reference.Volatile.eref
```
Reference used to remember if the user is already preregistered.

```ocaml
val action_link_key_outdated : bool Eliom_reference.Volatile.eref
```
Reference used to remember if an action link key is outdated.

```ocaml
val userid_of_user : Os_types.User.t -> Os_types.User.id
```
`userid_of_user user` returns the userid of the user `user`.

```ocaml
val firstname_of_user : Os_types.User.t -> string
```
`firstname_of_user user` returns the first name of the user `user`

```ocaml
val lastname_of_user : Os_types.User.t -> string
```
`lastname_of_user user` returns the last name of the user `user`

```ocaml
val avatar_of_user : Os_types.User.t -> string option
```
`avatar_of_user user` returns the avatar of the user `user` as `Some avatar_uri`. It returns `None` if the user `user` has no avatar.

```ocaml
val avatar_uri_of_avatar : 
  ?absolute_path:bool ->
  string ->
  Eliom_content.Xml.uri
```
`avatar_uri_of_avatar ?absolute_path avatar` returns the URI (absolute or relative) depending on the value of `absolute_path`) of the avatar `avatar`.

```ocaml
val avatar_uri_of_user : 
  ?absolute_path:bool ->
  Os_types.User.t ->
  Eliom_content.Xml.uri option
```
`avatar_uri_of_user user` returns the avatar URI (absolute or relative) depending on the value of `absolute_path`) of the avatar of the user `user`. It returns `None` is the user `user` has no avatar.

```ocaml
val language_of_user : Os_types.User.t -> string option
```
`language_of_user user` returns the language of the user `user`

```ocaml
val fullname_of_user : Os_types.User.t -> string
```
Retrieve the full name of user (which is the concatenation of the first name and last name).

```ocaml
val is_complete : Os_types.User.t -> bool
```
`is_complete user` returns `true` if the first name and the last name of `Os_types.user` have been completed yet.

```ocaml
val add_actionlinkkey : 
  ?autoconnect:bool ->
  ?action:[ `AccountActivation | `PasswordReset | `Custom of string ] ->
  ?data:string ->
  ?validity:int64 ->
  ?expiry:CalendarLib.Calendar.t ->
  act_key:string ->
  userid:Os_types.User.id ->
  email:string ->
  unit ->
  unit Lwt.t
```
`add_actionlinkkey ?autoconnect ?action ?data ?validity ?expiry ~act_key ~userid ~email ()` adds the action key in the database.

```ocaml
val verify_password : email:string -> password:string -> Os_types.User.id Lwt.t
```
`verify_password ~email ~password` returns the userid if user with email `email` is registered with the password `password`. If `password` the password is wrong, it fails with exception `Wrong_password`. If user exists but account is not validated, it fails with exception `Account_not_activated`. If user has no password, it fails with exception `Password_not_set`. If user is not found, it fails with exception [`No_such_user`](./#exception-No_such_user). If password is empty, it fails with exception `Empty_password`.

```ocaml
val user_of_userid : Os_types.User.id -> Os_types.User.t Lwt.t
```
`user_of_userid userid` returns the information about the user with ID `userid`.

```ocaml
val get_actionlinkkey_info : string -> Os_types.Action_link_key.info Lwt.t
```
Retrieve the data corresponding to an action link key, each call decrements the validity of the key by `1` if it exists and `validity > 0` (it remains at `0` if it's already `0`). It is up to you to adapt the actions according to the value of validity\! Raises [`Os_db.No_such_resource`](./Os_db.md#exception-No_such_resource) if the action link key is not found.

```ocaml
val userid_of_email : string -> Os_types.User.id Lwt.t
```
`userid_of_email email` returns the userid of the user with email `email`. It raises the exception [`Os_db.No_such_resource`](./Os_db.md#exception-No_such_resource) if the email `email` is not used.

```ocaml
val emails_of_userid : Os_types.User.id -> string list Lwt.t
```
`emails_of_userid userid` returns the emails list of user with ID `userid`.

```ocaml
val email_of_userid : Os_types.User.id -> string option Lwt.t
```
`email_of_userid userid` returns the main email of user with ID `userid`.

```ocaml
val emails_of_user : Os_types.User.t -> string list Lwt.t
```
`emails_of_user user` returns the emails list of user `user`.

```ocaml
val email_of_user : Os_types.User.t -> string option Lwt.t
```
`email_of_user user` returns the main email of user `user`.

```ocaml
val get_language : Os_types.User.id -> string option Lwt.t
```
`get_language userid` returns the language of the user with ID `userid`. The language is retrieved from the database.

```ocaml
val get_users : ?pattern:string -> unit -> Os_types.User.t list Lwt.t
```
`get_users ?pattern ()` gets users who match the `pattern` (useful for completion).

```ocaml
val create : 
  ?password:string ->
  ?avatar:string ->
  ?language:string ->
  ?email:string ->
  firstname:string ->
  lastname:string ->
  unit ->
  Os_types.User.t Lwt.t
```
`create ?password ?avatar ?language ~firstname ~lastname email` creates a new user with the given information. An email, the first name and the last name are mandatory.

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
`update ?password ?avatar ?language ~firstname ~lastname userid` update the given information of the user with ID `userid`. Only given information are updated.

```ocaml
val update' : ?password:string -> Os_types.User.t -> unit Lwt.t
```
Another version of `update` using a type [`Os_types.User.t`](./Os_types-User.md#type-t) instead of label.

```ocaml
val update_password : userid:Os_types.User.id -> password:string -> unit Lwt.t
```
`update_password ~userid ~password` updates the password only. `password` must not be hashed: it is done by the function `f_crypt` of the tuple [`Os_db.pwd_crypt_ref`](./Os_db.md#val-pwd_crypt_ref).

```ocaml
val update_avatar : userid:Os_types.User.id -> avatar:string -> unit Lwt.t
```
`update_avatar ~userid ~avatar` updates the avatar of the user with ID `userid`.

```ocaml
val update_language : userid:Os_types.User.id -> language:string -> unit Lwt.t
```
`update_language ~userid ~language` updates the language of the user with ID `userid`.

```ocaml
val is_registered : string -> bool Lwt.t
```
`is_registered email` returns `true` if a user exists with email `email`. Else, it returns `false`.

```ocaml
val is_preregistered : string -> bool Lwt.t
```
`is_preregistered email` returns `true` if a user exists with email `email`. Else, it returns `false`.

```ocaml
val add_preregister : string -> unit Lwt.t
```
`add_preregister email` adds an email into the preregister collections.

```ocaml
val remove_preregister : string -> unit Lwt.t
```
`remove_preregister email` removes an email from the preregister collections.

```ocaml
val all : ?limit:int64 -> unit -> string list Lwt.t
```
Get `limit` (default: 10\) emails from the preregister collections.

```ocaml
val set_pwd_crypt_fun : 
  ((string -> string) * (Os_types.User.id -> string -> string -> bool)) ->
  unit
```
By default, passwords are encrypted using Bcrypt. You can customize this by calling this function with a pair of function (crypt and check password). The first parameter of the second function is the user id (in case you need it). Then it takes as second parameter the password given by user, and as third parameter the hash found in database.

```ocaml
val remove_email_from_user : 
  userid:Os_types.User.id ->
  email:string ->
  unit Lwt.t
```
`remove_email_from_user ~userid ~email` removes the email `email` from the user with the id `userid`. If the email is registered as the main email for the user it fails with the exception [`Os_db.Main_email_removal_attempt`](./Os_db.md#exception-Main_email_removal_attempt).

```ocaml
val is_email_validated : userid:Os_types.User.id -> email:string -> bool Lwt.t
```
`is_email_validated ~userid ~email` returns whether for a user designated by its id the given email has been validated.

```ocaml
val is_main_email : userid:Os_types.User.id -> email:string -> bool Lwt.t
```
`is_main_email ~userid ~email` returns whether an email is the main email registered for a given user designated by its id.

```ocaml
val update_main_email : userid:Os_types.User.id -> email:string -> unit Lwt.t
```
`update_mail_email ~userid ~email` sets the main email for a user with the ID `userid` as the email `email`.
