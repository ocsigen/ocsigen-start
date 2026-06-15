
# Module `Os_msg`

```ocaml
val msg : 
  ?level:[ `Err | `Msg ] ->
  ?duration:float ->
  ?onload:bool ->
  string ->
  unit
```
Call this function either from client or server side to display an error message in the page.

The message is displayed in a special box (a `"div"` with id `"os_msg"` created automatically in the body of the page).

It is displayed during a short amount of time then disappears. You may change the duration in seconds with the parameter `duration` (default can be set using function [`Os_msg.set_default_duration`](./#val-set_default_duration)).

The two levels correspond to different classes that you can personalize by modifying the CSS class `"os_err"` (added for error messages to the box with ID `"os_msg"`).

If `?onload` is `true`, the message is displayed after the next page is displayed (default `false`). When called on server side, this is always the case.

```ocaml
val set_default_duration : float -> unit
```
Set default message duration (default 4s)

```ocaml
val action_link_key_created : bool Eliom_reference.Volatile.eref
```
Set to `true` if an action link key has been already created and sent to the user email, else `false`. Default is `false`.

```ocaml
val wrong_pdata : 
  ((string * string) * (string * string)) option Eliom_reference.Volatile.eref
```
`((firstname, lastname), (password, password_confirmation)) option` is a reference used to remember information about the user during a request when something went wrong (for example in a form when the password and password confirmation are not the same).

If the value is `None`, no user data has been set. Default is `None`.
