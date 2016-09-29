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

[%%server.start]

val action_link_handler :
  int64 option ->
  string ->
  unit ->
  'a Eliom_registration.application_content Eliom_registration.kind Lwt.t

[%%client.start]

val action_link_handler :
  int64 option ->
  string ->
  unit ->
  'b Eliom_registration.application_content Eliom_registration.kind Lwt.t

[%%server.start]

val forgot_password_handler :
  (unit, unit, Eliom_service.get, Eliom_service.att, _,
   Eliom_service.non_ext, _, _, unit, unit, 'c)
    Eliom_service.t ->
  unit -> string -> unit Lwt.t

val preregister_handler :
  unit -> string -> unit Lwt.t

val set_password_handler : Os_user.id -> unit -> string * string -> unit Lwt.t

val set_personal_data_handler :
  Os_user.id -> unit -> (string * string) * (string * string) -> unit Lwt.t

[%%client.start]

val set_password_rpc : string * string -> unit Lwt.t

val restart : unit -> unit
