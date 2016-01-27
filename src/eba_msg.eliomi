(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
 *
 * Copyright (C) 2014
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

[%%shared.start]

(** Call this function either from client or server side
    to display an error message in the page.
    The message is displayed in a special box created automatically
    in the body of the page.
    It is displayed during a short amount of time then disappears.
    The two levels correspond to different classes that you can
    personalize in CSS.
*)
val msg : ?level:[`Err | `Msg] -> string -> unit

[%%server.start]

val activation_key_created : bool Eliom_reference.Volatile.eref
val wrong_pdata
  : ((string * string) * (string * string)) option Eliom_reference.Volatile.eref
