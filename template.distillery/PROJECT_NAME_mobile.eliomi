(* WARNING generated in an ad-hoc fashion. Use with care! *)
[%%server.start]
val init_request : 'a -> unit -> unit Lwt.t

val init_request_rpc :
  (Deriving_Json.Json_unit.a, unit) Eliom_client.server_function

[%%client.start]

val add_listeners : unit -> unit
