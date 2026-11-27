# Module `Os.Comet`

```ocaml
val __link : unit
```
```ocaml
val restart_process : unit -> unit
```
`restart_process ()` restarts the client. For mobile application, it restarts the application by going to `"index.html"`. For other types of clients, [`Eliom.Service.reload_action`](./../../eliom/eliom.client/Eliom-Service.md#val-reload_action) is used as argument of [`Eliom.Client.exit_to`](./../../eliom/eliom.client/Eliom-Client.md#val-exit_to)

```ocaml
val set_error_handler : (exn -> unit Lwt.t) -> unit
```
