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

let%client () = print_endline "[DEBUG] Os_icons"

[%%shared
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

module D = struct
  let user_r = ref Ot_icons.D.user
  let signout_r = ref Ot_icons.D.signout
  let close_r = ref Ot_icons.D.close

  let user ?a () =
    (!user_r ?a ()
      : Html_types.i Eliom_content.Html.D.elt
      :> [> Html_types.i] Eliom_content.Html.D.elt)

  let signout ?a () =
    (!signout_r ?a ()
      : Html_types.i Eliom_content.Html.D.elt
      :> [> Html_types.i] Eliom_content.Html.D.elt)

  let close ?a () =
    (!close_r ?a ()
      : Html_types.i Eliom_content.Html.D.elt
      :> [> Html_types.i] Eliom_content.Html.D.elt)
end

module F = struct
  let user_r = ref Ot_icons.F.user
  let signout_r = ref Ot_icons.F.signout
  let close_r = ref Ot_icons.F.close

  let user ?a () =
    (!user_r ?a ()
      : Html_types.i Eliom_content.Html.D.elt
      :> [> Html_types.i] Eliom_content.Html.D.elt)

  let signout ?a () =
    (!signout_r ?a ()
      : Html_types.i Eliom_content.Html.D.elt
      :> [> Html_types.i] Eliom_content.Html.D.elt)

  let close ?a () =
    (!close_r ?a ()
      : Html_types.i Eliom_content.Html.D.elt
      :> [> Html_types.i] Eliom_content.Html.D.elt)
end

module Register (FF : ICSIG) (DD : ICSIG) = struct
  D.user_r := DD.user;
  D.signout_r := DD.signout;
  D.close_r := DD.close;
  F.user_r := FF.user;
  F.signout_r := FF.signout;
  F.close_r := FF.close
end]
