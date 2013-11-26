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
  module Groups : Eba_groups.T
  module Session : Eba_session.T
  module Services : Eba_services.T
  module Email : Eba_email.T
  module Page : Eba_page.T
  module Rmsg : Eba_rmsg.T

  module G : Eba_groups.T
  module Ss : Eba_session.T
  module Sv : Eba_services.T
  module E : Eba_email.T
  module R : Eba_rmsg.T
  module P : Eba_page.T
end
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

  module Session = Eba_session.Make(
  struct
    module Groups = Groups

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
  module P = Page
  module St = State
  module Ss = Session
  module Sv = Services
  module G = Groups
end
