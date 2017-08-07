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

(** [reload ()] reloads the current page. *)
val reload : unit -> unit Lwt.t

[%%shared.start]

module Email_or_phone : sig

  type t [@@deriving json]

  type y = [`Email | `Phone]

  val y : t -> y

  val to_string : t -> string

  val of_string : only_mail:bool -> string -> t option

  module Almost : sig

    type t [@@deriving json]

    type nonrec y = [ y | `Almost_phone | `Almost_email | `Invalid ]
    [@@deriving json]

    val y : t -> y

    val to_string : t -> string

    val of_string : only_mail:bool -> string -> t

  end

  val of_almost : Almost.t -> t option

end

val phone_regexp : Re_str.regexp

val email_regexp : Re_str.regexp

(** [memoizator f ()] caches the returned value of [f ()] *)
val memoizator :
  (unit -> 'a Lwt.t)  ->
  unit                ->
  'a Lwt.t

val string_repeat : string -> int -> string

val string_filter : (char -> bool) -> string -> string

[%%server.start]
(** This module contains functions about HTTP request. *)
module Http :
  sig
    (** [string_of_stream ?len stream] creates a string of maximum length [len]
        (default is [16384]) from the stream [stream].
     *)
    val string_of_stream : ?len:int -> string Ocsigen_stream.t -> string Lwt.t
  end
