(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
 *
 * Copyright (C) 2014
 *      Charly Chevalier
 *      Vincent Balat
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)
(* Copyright Vincent Balat, Séverine Maingaud *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

module type ParamT = sig
  val app_name : string

  module Groups : Eba_sigs.Groups

  module Page : Eba_config.Page
  module Session : Eba_config.Session
  module Email : Eba_config.Email
  module State : Eba_config.State
end

module App(M : ParamT)

(*VVV FIX! Removing the signature as some functions are missing
  (used by xprime) *)
(* : sig
  module App : Eba_sigs.App
  module Session : Eba_sigs.Session
    with type group = M.Groups.t
  module Email : Eba_sigs.Email
  module Page : Eba_sigs.Page with module Session = Session
  module Tools : Eba_sigs.Tools
  module Reqm : Eba_sigs.Reqm
  module State : Eba_sigs.State
    with type state = M.State.t

  module R : Eba_sigs.Reqm
  module E : Eba_sigs.Email
  module P : Eba_sigs.Page
  module St : Eba_sigs.State
  module Ss : Eba_sigs.Session
  module T : Eba_sigs.Tools
end *)
=
struct
  module App = struct
    include Eliom_registration.App(struct
      let application_name = M.app_name
    end)

    let app_name = M.app_name
  end

  module State = Eba_state.Make(M.State)(App)
  module Email = Eba_email.Make(M.Email)
  module Session = Eba_session.Make(M.Session)(M.Groups)
  module Page = Eba_page.Make(M.Page)(Session)
  module Reqm = Eba_reqm
  module Tools = Eba_tools

  module R = Reqm
  module T = Tools
  module E = Email
  module P = Page
  module St = State
  module Ss = Session
end
