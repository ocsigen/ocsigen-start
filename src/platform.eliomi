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

(** About device platform. *)

[%%shared.start]

(** Platform type. *)
type t =
  | Android
  | IPhone
  | IPad
  | IPod
  | IWatch
  | BlackBerry
  | Windows
  | Unknown

val t_of_string : string -> t
val string_of_t : t -> string

[%%client.start]

val get : unit -> t
(** Return the platform as a type {!t}.
    The detection is based on the user agent.
 *)

[%%shared.start]

val css_class : t -> string
(** Return ["os-platform"] where [platform] is the device platform.

    CSS class for [IPhone], [IPad], [IWatch] and [IPod] is
    ["os-ios"].

    If the platform is [Unknown], it returns ["os-unknown-platform"].
 *)
