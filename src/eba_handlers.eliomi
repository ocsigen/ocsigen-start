[%%server.start]

val connect_handler : unit -> (string * string) * bool ->
  Eliom_registration.browser_content Eliom_registration.kind Lwt.t

[%%client.start]

val connect_handler : unit -> (string * string) * bool -> unit Lwt.t

[%%shared.start]

val disconnect_handler : unit -> unit -> unit Lwt.t

val sign_up_handler : unit -> string -> unit Lwt.t

[%%server.start]

val activation_handler :
  string -> unit ->
  Eliom_registration.browser_content Eliom_registration.kind Lwt.t

val forgot_password_handler :
  (unit, unit, Eliom_service.get, Eliom_service.att, _,
   Eliom_service.non_ext, _, _, unit, unit, 'c)
    Eliom_service.t ->
  unit -> string -> unit Lwt.t

val preregister_handler' :
  unit -> string -> unit Lwt.t

val set_password_handler' : int64 -> unit -> string * string -> unit Lwt.t

val set_personal_data_handler' :
  int64 -> unit -> (string * string) * (string * string) -> unit Lwt.t

[%%client.start]

val activation_handler : string -> unit Lwt.t
val set_password_rpc : string * string -> unit Lwt.t
