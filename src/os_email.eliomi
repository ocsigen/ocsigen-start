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

(** Basic module for sending e-mail messages to users,
    using some local sendmail program.
*)

val set_from_addr : string * string -> unit
(** [set_from_addr (sender_name, sender_email)] sets the email address used to
    send mail to [sender_email] and the sender name to [sender_name]. *)

val set_mailer : string -> unit
(** [set_mailer mailer] sets the name of the external [sendmail] program on your
    system, used by the default {!send} function. *)

val get_mailer : unit -> string
(** [get_mailer ()] returns the name of mailer program. *)

exception Invalid_mailer of string
(** Exception raised if the mailer is invalid. You can raise an exception of
    this type in email sending function if you use {!set_send}.
 *)

val email_pattern : string
(** The pattern used to check the validity of an e-mail address. *)

val is_valid : string -> bool
(** [is_valid email] returns [true] if the e-mail address [email] is valid. Else
    it returns [false]. *)

val send :
   ?url:string
  -> ?from_addr:string * string
  -> to_addrs:(string * string) list
  -> subject:string
  -> string list
  -> unit
(** Send an e-mail to [to_addrs] from [from_addr]. You have to define the
    [subject] of your email. The body of the email is a list of strings
    and each element of the list is automatically separated by a new line.
    Tuples used by [from_addr] and [to_addrs] is of the form [(name, email)].
    *)

val set_send :
   (?url:string
    -> from_addr:string * string
    -> to_addrs:(string * string) list
    -> subject:string
    -> string list
    -> unit)
  -> unit
(** Customize email sending function. See {!send} for more details about the
    arguments.
 *)
