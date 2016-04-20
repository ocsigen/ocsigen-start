
[%%shared.start]

val connect_handler : unit -> (string * string) * bool -> unit Lwt.t

val disconnect_handler : unit -> unit -> unit Lwt.t

[%%server.start]

val activation_handler :
  string -> unit ->
  Eliom_registration.browser_content Eliom_registration.kind Lwt.t

val forgot_password_handler :
  (unit, unit, [< `Get ], [< Eliom_service.attached_kind ],
   [< `AttachedCoservice | `Service ], [< Eliom_service.suff ],
   unit, unit, [< Eliom_service.registrable ], 'a)
    Eliom_service.service -> unit -> string -> unit Lwt.t

val preregister_handler' :
  unit -> string -> unit Lwt.t

val sign_up_handler' :
  unit -> string -> unit Lwt.t

val set_password_handler' : int64 -> unit -> string * string -> unit Lwt.t

val set_personal_data_handler' :
  int64 -> unit -> (string * string) * (string * string) -> unit Lwt.t
