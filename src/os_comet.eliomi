(* WARNING generated in an ad-hoc fashion. Use with care! *)
[%%shared.start]
val __link : unit

type msg = Connection_changed | Heartbeat

[%%client.start]

val restart_process :
  unit ->
  unit

val handle_message : msg Lwt_stream.result -> unit Lwt.t

[%%server.start]

val create_monitor_channel :
  unit -> 'a Eliom_comet.Channel.t * ('a option -> unit)

val monitor_channel_ref :
  (msg Eliom_comet.Channel.t * (msg option -> unit)) option
  Eliom_reference.Volatile.eref

val already_send_ref : bool Eliom_reference.Volatile.eref
