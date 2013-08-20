(** Flash messages are used when you want to handle potentials errors/warnings
    after a request.

    Currently there is only one flash error by request but maybe,
    this could be a list ?

    Flash messages are represented by a variant, so each messages are unique and
    they can be handled differently from each other.
  *)

(* QUESTION:
   - Flash message type could be a polymorphic variant ?
     To let the user define his own flash message and handle them.
   - Flash message could be represented by a list of flash_msg_t, to handle
     multiple flash messages ?
 *)

type flash_msg_t =
  | No_flash_msg
  | Wrong_password
  | Activation_key_outdated
  | User_already_preregistered of string
  | User_does_not_exist of string
  | User_already_exists of string

let flash_msg : flash_msg_t option Eliom_reference.Volatile.eref =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope None

let set_flash_msg (e : flash_msg_t)  =
  Eliom_reference.Volatile.set flash_msg (Some e)

let get_flash_msg ()  =
  match Eliom_reference.Volatile.get flash_msg with
    | None -> Lwt.return No_flash_msg
    | Some e -> Lwt.return e

let get_ref_flash_msg () =
  Eliom_reference.Volatile.get flash_msg

let has_flash_msg () =
  match Eliom_reference.Volatile.get flash_msg with
    | None -> Lwt.return false
    | Some _ -> Lwt.return true

