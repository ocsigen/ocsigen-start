
# Module type `Os_notif.ARG`

`ARG` is for making `Make`. It is a simplified version of `Eliom_notif.ARG`.

```ocaml
type key
```
```ocaml
type server_notif
```
```ocaml
type client_notif
```
```ocaml
val prepare : 
  Os_types.User.id option ->
  server_notif ->
  client_notif option Lwt.t
```
```ocaml
val equal_key : key -> key -> bool
```
```ocaml
val max_resource : int
```
```ocaml
val max_identity_per_resource : int
```