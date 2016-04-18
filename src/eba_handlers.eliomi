
val connect_handler : unit -> (string * string) * bool -> unit Lwt.t
val disconnect_handler : unit -> unit -> unit Lwt.t
val activation_handler :
  string -> unit ->
  Eliom_registration.browser_content Eliom_registration.kind Lwt.t

val set_password_handler' : int64 -> unit -> string * string -> unit Lwt.t
val set_personal_data_handler' :
  int64 -> unit -> (string * string) * (string * string) -> unit Lwt.t
