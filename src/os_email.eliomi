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

(** Basic module for sending e-mail messages to users,
    using some local sendmail program.
*)

(** Set the email address used to send mail *)
val set_from_addr : (string * string) -> unit

(** Set the name of the external [sendmail] program on your system,
    used by the default send function *)
val set_mailer : string -> unit

(** Get the name of mailer program *)
val get_mailer : unit -> string

exception Invalid_mailer of string

(** The pattern used to check the validity of an e-mail address *)
val email_pattern : string

(** Check if the given e-mail address is valid or not *)
val is_valid : string -> bool

(** Send an e-mail to [to_addrs]. You have to define the [subject] of your
    email. The body of the email is a list of strings
    and each element of the list is automatically separated by a new line. *)
val send :
  ?from_addr:(string * string) ->
  to_addrs:((string * string) list) ->
  subject:string ->
  string list ->
  unit Lwt.t

(** Customize email sending function: *)
val set_send :
  (from_addr:(string * string) ->
   to_addrs:((string * string) list) ->
   subject:string ->
   string list ->
   unit Lwt.t) -> unit
