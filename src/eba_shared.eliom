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

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

{server{
  module Session = struct
    exception Not_connected
  end
}}

{client{
  module Session = struct
    exception Not_connected

    let userid : int64 option ref = ref None

    let set_current_userid uid =
      userid := Some uid

    let unset_current_userid () =
      userid := None

    let get_current_userid () =
      match !userid with
        | Some userid -> userid
        | None -> raise Not_connected

    module Opt = struct
      let get_current_userid () =
        !userid
    end
  end
}}

{server{
  module Page = struct
    type page =
      [ Html5_types.html ] Eliom_content.Html5.elt
    type page_content =
      [ Html5_types.body_content ] Eliom_content.Html5.elt list
    type head_content =
      Html5_types.head_content_fun Eliom_content.Html5.elt list
  end
}}

{shared{
  module Email' = struct
    let email_pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+[.][A-Z]+$"
  end
}}

{client{
  module Email = struct
    include Email'

    let regexp_email =
      Regexp.regexp_with_flag email_pattern "i"

    let is_valid email =
      match Regexp.string_match regexp_email email 0 with
        | None -> false
        | Some _ -> true
  end
}}

{server{
  module Email = struct
    include Email'
  end
}}
