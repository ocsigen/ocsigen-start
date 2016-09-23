[%%server.start]

(* ------------------------------ *)
(* Comes from include Os_handlers *)

val connect_handler : unit -> (string * string) * bool -> unit Lwt.t

val disconnect_handler : unit -> unit -> unit Lwt.t

val sign_up_handler : unit -> string -> unit Lwt.t

val add_email_handler : unit -> string -> unit Lwt.t

(* Comes from include Os_handlers *)
(* ------------------------------ *)

val upload_user_avatar_handler :
  Os_user.id ->
  unit ->
  unit *
    ((float * float * float * float) option * Ocsigen_extensions.file_info) ->
  unit Lwt.t

val set_personal_data_handler' :
  unit -> (string * string) * (string * string) -> unit Lwt.t

val forgot_password_handler :
  unit -> string -> unit Lwt.t

[%%client.start]

val set_personal_data_handler' :
  unit ->
  (Deriving_Json.Json_string.a * Deriving_Json.Json_string.a) *
  (Deriving_Json.Json_string.a * Deriving_Json.Json_string.a) -> unit Lwt.t

val forgot_password_handler :
  unit -> Deriving_Json.Json_string.a -> unit Lwt.t

[%%shared.start]

val activation_handler :
  string -> unit -> Eliom_registration.Action.result Lwt.t

val set_password_handler' : unit -> string * string -> unit Lwt.t

val preregister_handler' : unit -> string -> unit Lwt.t

val main_service_handler :
  Os_user.id option ->
  unit ->
  unit -> [> `Div | `Footer | `Nav ] Eliom_content.Html.F.elt list Lwt.t

val about_handler :
  Os_user.id option ->
  unit ->
  unit -> [> `Div | `Footer | `Nav ] Eliom_content.Html.F.elt list Lwt.t

val settings_handler :
  Os_user.id option ->
  unit ->
  unit -> [> `Div | `Footer | `Nav ] Eliom_content.Html.F.elt list Lwt.t
