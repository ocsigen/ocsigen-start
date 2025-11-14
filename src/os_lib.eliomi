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

(** This module aims to provide common utilities functions. *)

[%%client.start]

val reload : unit -> unit Lwt.t
(** [reload ()] reloads the current page. *)

[%%shared.start]

(** Parse strings that can be e-mails or phones. *)
module Email_or_phone : sig
  type t [@@deriving json]
  type y = [`Email | `Phone]

  val y : t -> y
  val to_string : t -> string
  val of_string : only_mail:bool -> string -> t option

  module Almost : sig
    type t [@@deriving json]

    type y = [`Email | `Phone | `Almost_phone | `Almost_email | `Invalid]
    [@@deriving json]

    val y : t -> y
    val to_string : t -> string
    val of_string : only_mail:bool -> string -> t
  end

  val of_almost : Almost.t -> t option
end

val phone_regexp : Re.Str.regexp
val email_regexp : Re.Str.regexp

val memoizator : (unit -> 'a) -> unit -> 'a
(** [memoizator f ()] caches the returned value of [f ()] *)

val string_repeat : string -> int -> string
val string_filter : (char -> bool) -> string -> string

val lwt_bound_input_enter :
   ?a:[< Html_types.input_attrib] Eliom_content.Html.attrib list
  -> ?button:[< Html_types.button] Eliom_content.Html.elt
  -> ?validate:(string -> bool) Eliom_client_value.t
  -> (string -> unit) Eliom_client_value.t
  -> [> `Input] Eliom_content.Html.elt
(** [lwt_bound_input_enter f] produces an input element bound to [f],
    i.e., when the user submits the input, we call [f]. *)

val lwt_bind_input_enter :
   ?validate:(string -> bool) Eliom_client_value.t
  -> ?button:[< Html_types.button | Html_types.input] Eliom_content.Html.elt
  -> Html_types.input Eliom_content.Html.elt
  -> (string -> unit) Eliom_client_value.t
  -> unit
(** [lwt_bound_input_enter inp f] calls f whenever the user submits
    the contents of [inp]. *)

[%%server.start]

(** This module contains functions about HTTP request. *)
module Http : sig
  val string_of_stream : ?len:int -> string Ocsigen_stream.t -> string
  (** [string_of_stream ?len stream] creates a string of maximum length [len]
        (default is [16384]) from the stream [stream].
     *)
end
