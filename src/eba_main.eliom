(* Copyright Vincent Balat, Séverine Maingaud *)

(** Main module. Web interaction.
    Definition of service handlers and registration of services. *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

module type ParamT = sig
  type state_t = private [> Eba_types.state_t ] deriving (Json)
  type error_t = private [> Eba_types.error_t ] deriving (Json)
  type notice_t = private [> Eba_types.notice_t ] deriving (Json)

  val app_name : string
  val states : (state_t * string * string option) list

  val page_config : Eba_page.config
  val session_config : Eba_session.config
  val email_config : Eba_email.config

  module Database : Eba_database.T
end

module App(M : ParamT) : sig
  module App : sig include Eliom_registration.ELIOM_APPL val app_name : string end
  module User : Eba_user.T
  module Groups : Eba_groups.T
  module Session : Eba_session.T
  module Services : Eba_services.T
  module Page : Eba_page.T
  module Rmsg : Eba_rmsg.T

  module U : Eba_user.T
  module G : Eba_groups.T
  module Ss : Eba_session.T
  module Sv : Eba_services.T
  module R : Eba_rmsg.T
  module P : Eba_page.T
end with type User.t = M.Database.User.ext_t
=
struct
  module App = struct
    include Eliom_registration.App(
    struct
      let application_name = M.app_name
    end)

    let app_name = M.app_name
  end

  module Groups =
    Eba_groups.Make(M.Database.Groups)

  module State = Eba_state.Make(
  struct
    let app_name = M.app_name
    let states = M.states

    type t = M.state_t deriving (Json)
  end)

  module Rmsg = Eba_rmsg.Make(
  struct
    type error_t = M.error_t
    type notice_t = M.notice_t
  end)

  module Email = Eba_email.Make(
  struct
    let app_name = M.app_name
    let config = M.email_config

    module Rmsg = Rmsg
  end)

  module User = Eba_user.Make(
  struct
    include M.Database.User
    module App = App
    module Email = Email
    module Rmsg = Rmsg
  end)

  module Session = Eba_session.Make(
  struct
    module Groups = Groups
    module User = User

    let config = M.session_config
  end)

  module Page = Eba_page.Make(
  struct
    let config = M.page_config
    module Session = Session
  end)

  module Services = Eba_services

  module R = Rmsg
  module E = Email
  module U = User
  module P = Page
  module St = State
  module Ss = Session
  module Sv = Services
  module G = Groups

  let disconnect_handler () () =
    (* SECURITY: no check here because we disconnect the session cookie owner. *)
    lwt () = Session.disconnect () in
    lwt () = Eliom_state.discard ~scope:Eliom_common.default_session_scope () in
    lwt () = Eliom_state.discard ~scope:Eliom_common.default_process_scope () in
    Eliom_state.discard ~scope:Eliom_common.request_scope ()

  let connect_handler () (login, pwd) =
    (* SECURITY: no check here. *)
    lwt () = disconnect_handler () () in
    match_lwt User.verify_password login pwd with
      | Some uid -> Session.connect uid
      | None ->
          R.Error.push `Wrong_password;
          Lwt.return ()

  (** service which will be attach to the current service to handle
    * the activation key (the attach_coservice' will be done on
    * Session.connect_wrapper_function *)
  let activation_handler akey () =
    (* SECURITY: we disconnect the user before doing anything
     * moreover in this case, if the user is already disconnect
     * we're going to disconnect him even if the actionvation key
     * is outdated. *)
    lwt () = Session.disconnect () in
    match_lwt User.uid_of_activationkey akey with
      | None ->
        (* Outdated activation key *)
        R.Error.push `Activation_key_outdated;
        Eliom_registration.Action.send ()
      | Some uid ->
        (* If the activationkey is valid, we connect the user *)
        lwt () = Session.connect uid in
        Eliom_registration.Redirection.send Eliom_service.void_coservice'

  (********* Registration *********)
  let _ =
    Eliom_registration.Action.register
      Eba_services.connect_service
      connect_handler;

    Eliom_registration.Action.register
      Eba_services.disconnect_service
      disconnect_handler;

    Eliom_registration.Any.register
      Eba_services.activation_service
      activation_handler;
end
