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

(** The icons used internally by Ocsigen Start's library.
    Customize them with your own icons by calling module [Register]. *)

[%%shared.start]

module type ICSIG = sig
  val user :
     ?a:Html_types.i_attrib Eliom_content.Html.D.attrib list
    -> unit
    -> [> Html_types.i] Eliom_content.Html.D.elt

  val signout :
     ?a:Html_types.i_attrib Eliom_content.Html.D.attrib list
    -> unit
    -> [> Html_types.i] Eliom_content.Html.D.elt

  val close :
     ?a:Html_types.i_attrib Eliom_content.Html.D.attrib list
    -> unit
    -> [> Html_types.i] Eliom_content.Html.D.elt
end

module D : ICSIG
module F : ICSIG
module Register (_ : ICSIG) (_ : ICSIG) : sig end
