(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright (C) Université Paris Diderot, CNRS, INRIA, Be Sport.
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


[%%shared
  open Eliom_content.Html
  open Eliom_content.Html.F
]

let wrong_password =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let account_not_activated =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let user_already_exists =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let user_does_not_exist =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let user_already_preregistered =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let action_link_key_outdated =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let%shared reset_tips_service = Os_tips.reset_tips_service

let%shared reset_tips_link (close : (unit -> unit) Eliom_client_value.t) =
  let l = D.Raw.a [pcdata "See help again from beginning"] in
  ignore [%client (
    Lwt_js_events.(async (fun () ->
      clicks (To_dom.of_element ~%l)
        (fun _ _ ->
           ~%close ();
           Eliom_client.exit_to
             ~service:reset_tips_service
             () ();
           Lwt.return ()
        )));
  : unit)];
  l
