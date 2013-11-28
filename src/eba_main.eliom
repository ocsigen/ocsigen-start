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

  module Groups : sig
    type t
    val in_group : group:t -> userid:int64 -> bool Lwt.t
  end

  val app_name : string
  val states : (state_t * string * string option) list

  val page_config : Eba_page.config
  val session_config : Eba_session.config
  val email_config : Eba_email.config
end

module App(M : ParamT) : sig
  module App : sig include Eliom_registration.ELIOM_APPL val app_name : string end
  module Session : Eba_session.T
  module Email : Eba_email.T
  module Page : Eba_page.T
  module Tools : Eba_tools.T

  module E : Eba_email.T
  module P : Eba_page.T
  module St : Eba_state.T
  module Ss : Eba_session.T
  module T : Eba_tools.T
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

  module State = Eba_state.Make(
  struct
    let app_name = M.app_name
    let states = M.states

    type t = M.state_t deriving (Json)
  end)

  module Email = Eba_email.Make(struct
    let config = M.email_config
  end)

  module Session = Eba_session.Make(struct
      let config = M.session_config
    end)(M.Groups)

  module Page = Eba_page.Make(struct
      let config = M.page_config
    end)(Session)

  module Tools = Eba_tools

  module T = Tools
  module E = Email
  module P = Page
  module St = State
  module Ss = Session
end
