(* Ocsigen Start
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

(** To be used for signalling errors with SMS transmission *)
type sms_error_core = [`Unknown | `Send | `Limit | `Invalid_number]

[%%server.start]

(** [set_send_sms_handler f] registers [f] as the function to be
    called to send SMS messages. Used to send activation codes for
    connectivity by mail. *)
val set_send_sms_handler :
  (number:string -> string -> (unit, sms_error_core) result Lwt.t) -> unit

[%%shared.start]

type sms_error = [`Ownership | sms_error_core]

(** Send a validation code for a new e-mail address (corresponds to
    [confirm_code_signup] and [confirm_code_extra]). *)
val request_code : string -> (unit, sms_error) result Lwt.t

(** Send a validation code for recovering an existing address. *)
val request_recovery_code : string -> (unit, sms_error) result Lwt.t

(** Confirm validation code and add extra phone to account. *)
val confirm_code_extra : string -> bool Lwt.t

(** Confirm validation code and complete sign-up with the phone
    number. *)
val confirm_code_signup :
  first_name:string -> last_name:string ->
  code:string -> password:string ->
  unit -> bool Lwt.t

(** Confirm validation code and recover account. We redirect to the
    settings page for setting a new password. *)
val confirm_code_recovery : string -> bool Lwt.t

val connect :
  keepmeloggedin:bool ->
  password:string ->
  string ->
  [`Login_ok | `No_such_user | `Wrong_password | `Password_not_set] Lwt.t
