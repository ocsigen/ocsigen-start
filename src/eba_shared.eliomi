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
{server{
  module Session : sig
    exception Not_connected
  end
}}

{client{
  module Session : sig
    exception Not_connected

    val set_current_userid : int64 -> unit
    val get_current_userid : unit -> int64
    val unset_current_userid : unit -> unit
    module Opt : sig
      val get_current_userid : unit -> int64 option
    end
  end
}}

{server{
  module Page : sig
    type page =
      [ Html5_types.html ] Eliom_content.Html5.elt
    type page_content =
      [ Html5_types.body_content ] Eliom_content.Html5.elt list
    type head_content =
      Html5_types.head_content_fun Eliom_content.Html5.elt list
  end
}}

{client{
  module Email : sig
    val email_pattern : string
    val is_valid : string -> bool
  end
}}

{server{
  module Email : sig
    val email_pattern : string
  end
}}
