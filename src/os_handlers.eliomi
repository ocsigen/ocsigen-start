
[%%shared.start]

val connect_handler : unit -> (string * string) * bool -> unit Lwt.t

val disconnect_handler : unit -> unit -> unit Lwt.t

val sign_up_handler : unit -> string -> unit Lwt.t

val add_email_handler : unit -> string -> unit Lwt.t

exception Custom_action_link of
    Os_data.actionlinkkey_info
    * bool (* If true, the link corresponds to a phantom user
              (user who never created its account).
              In that case, you probably want to display a sign-up form,
              and in the other case a login form. *)

val action_link_handler :
  int64 option ->
  string ->
  unit ->
  'a Eliom_registration.application_content Eliom_registration.kind Lwt.t

[%%server.start]

val forgot_password_handler :
  (unit, unit, Eliom_service.get, Eliom_service.att, _,
   Eliom_service.non_ext, _, _, unit, unit, 'c)
    Eliom_service.t ->
  unit -> string -> unit Lwt.t

val preregister_handler' :
  unit -> string -> unit Lwt.t

val set_password_handler' : Os_user.id -> unit -> string * string -> unit Lwt.t

val set_personal_data_handler :
  Os_user.id -> unit -> (string * string) * (string * string) -> unit Lwt.t

[%%client.start]

val set_password_rpc : string * string -> unit Lwt.t

val restart : ?url:string -> unit -> unit
