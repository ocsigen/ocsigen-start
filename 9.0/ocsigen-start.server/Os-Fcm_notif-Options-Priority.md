# Module `Options.Priority`

This modules defines a type for priorities for the notifications. See https://firebase.google.com/docs/cloud-messaging/concept-options\#setting-the-priority-of-a-message

```ocaml
type t = 
  | Normal
  | High
```
Priority of the message. On iOS, `Normal` means 5 and `High` means 10\.
