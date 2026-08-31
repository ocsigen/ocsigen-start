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

It is displayed during a short amount of time then disappears. You may change the duration in seconds with the parameter `duration` (default can be set using function `Os_msg.set_default_duration`).

The two levels correspond to different classes that you can personalize by modifying the CSS class `"os_err"` (added for error messages to the box with ID `"os_msg"`).

If `?onload` is `true`, the message is displayed after the next page is displayed (default `false`). When called on server side, this is always the case.
