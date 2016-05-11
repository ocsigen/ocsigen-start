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

[%%shared
open Eliom_content.Html
open Eliom_content.Html.F
]

[%%client

   let msgbox () =
     let id = "eba_msg" in
     try
       Dom_html.getElementById id
     with
     | Not_found ->
       let b = To_dom.of_element (D.div ~a:[a_id id] []) in
       Dom.appendChild Dom_html.document##.body b;
       b

]

[%%shared

  let msg ?(level = `Err) ?(duration = 2.) msg =
    ignore [%client (
      let c = if ~%level = `Msg then [] else ["eba_err"] in
      Eliom_lib.debug "%s" ~%msg;
      let msg = To_dom.of_p (D.p ~a:[a_class c] [pcdata ~%msg]) in
      let msgbox = msgbox () in
      Dom.appendChild msgbox msg;
      Lwt.async (fun () ->
        (let%lwt () = Lwt_js.sleep ~%duration in
         Dom.removeChild msgbox msg;
         Lwt.return ()))
    : unit)]

]



let activation_key_created =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let wrong_pdata =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope
    (None : ((string * string) * (string * string)) option)
