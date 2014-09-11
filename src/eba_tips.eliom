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

{shared{
open Eliom_content.Html5
open Eliom_content.Html5.F
}}

module Stringset = Ocsigen_lib.String.Set

(* tips_seen is a group persistent reference recording which tips have
   ealready been seen by user *)
let tips_seen =
  Eliom_reference.eref
    ~persistent:"tips_seen1"
    ~scope:Eliom_common.default_group_scope
    Stringset.empty

(* We cache the set during a request *)
let seen_by_user =
  Eliom_reference.Volatile.eref_from_fun
    ~scope:Eliom_common.request_scope
    (fun () -> Eliom_reference.get tips_seen)

(* notice the server that a user has seen a tip *)
let tip_seen userid (name : string) =
  lwt prev = Eliom_reference.Volatile.get seen_by_user in
  Eliom_reference.set tips_seen (Stringset.add (name : string) prev)

let tip_seen_rpc =
  server_function Json.t<string> (Eba_session.connected_rpc tip_seen)

(* I want to see the tips again *)
let reset_tips userid () () = Eliom_reference.set tips_seen (Stringset.empty)

let reset_tips_service =
  Eliom_registration.Action.register_post_coservice'
    ~name:"resettips"
    ~post_params:Eliom_parameter.unit
    (Eba_session.connected_fun reset_tips)

let reset_tips_rpc =
  server_function Json.t<unit>
    (Eba_session.connected_rpc (fun userid -> reset_tips userid ()))

    {client{

       let reset_tips () = %reset_tips_rpc ()

        (* This thread is used to display only one tip at a time: *)
        let waiter = ref (lwt _ = Lwt_js_events.onload () in Lwt.return ())

(* actually display a tip *)
let display ?(class_=[])
    ?arrow ?top ?left ?right ?bottom ?height ?width
    ?(parent_node = Manip.Elt.body) ~name ~content ()
  =
  let current_waiter = !waiter in
  let new_waiter, new_wakener = Lwt.wait () in
  waiter := new_waiter;
  lwt () = current_waiter in
  let bec = D.div ~a:[a_class ["bec"]] [] in
  let close_button = Ow_icons.D.close () in
  let box =
    D.div ~a:[a_class ("tip"::class_)]
      (close_button::match arrow with None -> content | _ -> bec::content)
  in
  Lwt_js_events.(async (fun () ->
    clicks (To_dom.of_element close_button)
      (fun ev _ ->
         let () = Manip.removeSelf box in
         Lwt.async (fun () -> %tip_seen_rpc (name : string));
         Lwt.wakeup new_wakener ();
         Lwt.return ()
      )));
  Manip.appendToBody box;
  let box = To_dom.of_element box in
  Eliom_lib.Option.iter
    (fun v -> box##style##top <- Js.string (Printf.sprintf "%ipx" v))
    top;
  Eliom_lib.Option.iter
    (fun v -> box##style##left <- Js.string (Printf.sprintf "%ipx" v))
    left;
  Eliom_lib.Option.iter
    (fun v -> box##style##right <- Js.string (Printf.sprintf "%ipx" v))
    right;
  Eliom_lib.Option.iter
    (fun v -> box##style##bottom <- Js.string (Printf.sprintf "%ipx" v))
    bottom;
  Eliom_lib.Option.iter
    (fun v -> box##style##width <- Js.string (Printf.sprintf "%ipx" v))
    width;
  Eliom_lib.Option.iter
    (fun v -> box##style##height <- Js.string (Printf.sprintf "%ipx" v))
    height;
  Eliom_lib.Option.iter
    (fun a ->
       let bec = To_dom.of_element bec in
       match a with
       | `top i ->
         bec##style##top <- Js.string "-11px";
         bec##style##left <- Js.string (Printf.sprintf "%ipx" i);
         bec##style##borderBottom <- Js.string "none";
         bec##style##borderRight <- Js.string "none"
       | `left i ->
         bec##style##left <- Js.string "-11px";
         bec##style##top <- Js.string (Printf.sprintf "%ipx" i);
         bec##style##borderTop <- Js.string "none";
         bec##style##borderRight <- Js.string "none"
       | `bottom i ->
         bec##style##bottom <- Js.string "-11px";
         bec##style##left <- Js.string (Printf.sprintf "%ipx" i);
         bec##style##borderTop <- Js.string "none";
         bec##style##borderLeft <- Js.string "none"
       | `right i ->
         bec##style##right <- Js.string "-11px";
         bec##style##top <- Js.string (Printf.sprintf "%ipx" i);
         bec##style##borderBottom <- Js.string "none";
         bec##style##borderLeft <- Js.string "none"
    )
    arrow;
  Lwt.return ()

}}

(* Function to be called on server to display a tip *)
let display ?arrow ?top ?left ?right ?bottom ?height ?width
    ?parent_node ~(name : string) ~content () =
  lwt seen = Eliom_reference.Volatile.get seen_by_user in
  if Stringset.mem name seen
  then Lwt.return ()
  else let _ = {unit{ Lwt.async (fun () ->
      display ?arrow:%arrow
        ?top:%top ?left:%left ?right:%right ?bottom:%bottom
        ?height:%height ?width:%width
        ?parent_node:%parent_node ~name:(%name : string) ~content:%content ())
    }}
    in
    Lwt.return ()
