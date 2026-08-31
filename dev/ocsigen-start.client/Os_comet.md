# Module `Os_comet`

```ocaml
val __link : unit
```
```ocaml
val restart_process : unit -> unit
```
`restart_process ()` restarts the client. For mobile application, it restarts the application by going to `"index.html"`. For other types of clients, [`Eliom_service.reload_action`](./../../eliom/eliom.client/Eliom_service.md#val-reload_action) is used as argument of [`Eliom_client.exit_to`](./../../eliom/eliom.client/Eliom_client.md#val-exit_to)

```ocaml
val set_error_handler : (exn -> unit Lwt.t) -> unit
```
