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

open%client Eliom_content.Html
open%client Eliom_content.Html.F
open%client Js_of_ocaml

let%client msgbox () =
  let id = "os-msg" in
  try Dom_html.getElementById id
  with Not_found ->
    let b = To_dom.of_element (D.div ~a:[a_id id] []) in
    Dom.appendChild Dom_html.document##.body b;
    b

let%server default_duration = ref 4.
let%server set_default_duration d = default_duration := d

let%shared msg ?(level = `Err) ?(duration = ~%(!default_duration))
    ?(onload = false) (message : string)
  =
  ignore
    [%client
      (let c = if ~%level = `Msg then [] else ["os-err"] in
       let message_dom = To_dom.of_p (D.p ~a:[a_class c] [txt ~%message]) in
       Lwt.async (fun () ->
           let%lwt () =
             if ~%onload then Eliom_client.lwt_onload () else Lwt.return_unit
           in
           let msgbox = msgbox () in
           Eliom_lib.debug "%s" ~%message;
           Dom.appendChild msgbox message_dom;
           let%lwt () = Js_of_ocaml_lwt.Lwt_js.sleep ~%duration in
           Dom.removeChild msgbox message_dom;
           Lwt.return_unit)
        : unit)]

let action_link_key_created =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let wrong_pdata =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope
    (None : ((string * string) * (string * string)) option)
