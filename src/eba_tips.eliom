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
module Stringset = Set.Make(String)
]

(* tips_seen is a group persistent reference recording which tips have
   already been seen by user *)
let tips_seen =
  Eliom_reference.eref
    ~persistent:"tips_seen1"
    ~scope:Eliom_common.default_group_scope
    Stringset.empty
(*VVV TODO: What if not connected? We don't want to keep the eref
  for all non-connected users. This is a weakness of persistent
  group eref. Use posgresql instead? *)


(* We cache the set during a request *)
let seen_by_user =
  Eliom_reference.Volatile.eref_from_fun
    ~scope:Eliom_common.request_scope
    (fun () -> Eliom_reference.get tips_seen)

(* Get the set of seen tips *)
let%server get_tips_seen () = Eliom_reference.Volatile.get seen_by_user

(* We cache the set of seen tips to avoid doing the request several times.
   Warning: it is not updated if the user is using several devices or
   tabs at a time which means that the user may see the same tip several
   times in that case. *)
let%client tips_seen_client_ref = ref Stringset.empty
let%client get_tips_seen () = Lwt.return !tips_seen_client_ref

let%server () = Eba_session.on_start_connected_process
    (fun _ ->
       let%lwt tips = get_tips_seen () in
       ignore [%client (
         tips_seen_client_ref := ~%tips
       : unit)];
       Lwt.return ())

(* notify the server that a user has seen a tip *)
let set_tip_seen (name : string) =
  let%lwt prev = Eliom_reference.Volatile.get seen_by_user in
  Eliom_reference.set tips_seen (Stringset.add (name : string) prev)

let%client set_tip_seen name =
  tips_seen_client_ref := Stringset.add name !tips_seen_client_ref;
  ~%(Eliom_client.server_function
       ~name:"Eba_tips.set_tip_seen"
       [%derive.json: string]
       (Eba_session.connected_wrapper set_tip_seen))
  name

(* I want to see the tips again *)
let%server reset_tips_user userid =
  Eliom_reference.set tips_seen (Stringset.empty)

let reset_tips () =
  Eliom_lib.Option.Lwt.iter
    reset_tips_user
    (Eba_current_user.Opt.get_current_userid ())

let%server reset_tips_service =
  Eliom_service.create
    ~name:"resettips"
    ~id:Eliom_service.Global
    ~meth:
      (Eliom_service.Post (Eliom_parameter.unit, Eliom_parameter.unit))
    ()

let%client reset_tips_service = ~%reset_tips_service

let%server _ =
  Eliom_registration.Action.register
    ~service:reset_tips_service
    (Eba_session.connected_fun (fun myid () () -> reset_tips_user myid))

let%client reset_tips () =
  tips_seen_client_ref := Stringset.empty;
  ~%(Eliom_client.server_function
       ~name:"Eba_tips.reset_tips"
       [%derive.json: unit]
       (Eba_session.connected_wrapper reset_tips))
    ()

(* Returns a block containing a tip,
   if it has not already been seen by the user. *)
let%shared block ?(a = []) ~name ~content () =
  let myid_o = Eba_current_user.Opt.get_current_userid () in
  if myid_o = None
  then Lwt.return None
  else
    let%lwt seen = get_tips_seen () in
    if Stringset.mem name seen
    then Lwt.return None
    else begin
      let box_ref = ref None in
      let close = [%client (fun () ->
        let () = match !(~%box_ref) with
          | Some x -> Manip.removeSelf x
          | None -> () in
        Lwt.async (fun () -> set_tip_seen ~%name);
        Lwt.return () : _ -> _) ] in
      let box =
        D.div ~a:(a_class [ "tip" ; "block" ]::a)
          (Ot_icons.D.close ~a:[ a_onclick [%client fun _ ->
             Lwt.async ~%close ] ] ()
           :: content close)
      in
      box_ref := Some box ;
      Lwt.return (Some box)
    end

(* This thread is used to display only one tip at a time: *)
let%client waiter = ref (let%lwt _ = Lwt_js_events.onload () in Lwt.return ())

(* Display a tip bubble *)
let%client display_bubble ?(a = [])
    ?arrow ?top ?left ?right ?bottom ?height ?width
    ?(parent_node : _ elt option)
    ~name ~content ()
  =
  let current_waiter = !waiter in
  let new_waiter, new_wakener = Lwt.wait () in
  waiter := new_waiter;
  let%lwt () = current_waiter in
  let bec = D.div ~a:[a_class ["bec"]] [] in
  let box_ref = ref None in
  let close = fun () ->
    let () = match !box_ref with
      | Some x -> Manip.removeSelf x
      | None -> () in
    Lwt.async (fun () -> set_tip_seen (name : string));
    Lwt.wakeup new_wakener ();
    Lwt.return () in
  let box =
    D.div ~a:(a_class [ "tip" ; "bubble" ]::a)
      (Ot_icons.D.close ~a:[ a_onclick (fun _ -> Lwt.async close) ] ()
       :: match arrow with None -> content close
                         | _    -> bec :: content close)
  in
  box_ref := Some box ;
  let parent_node = match parent_node with
    | None -> Dom_html.document##.body
    | Some p -> To_dom.of_element p
  in
  Dom.appendChild parent_node (To_dom.of_element box);
  let box = To_dom.of_element box in
  Eliom_lib.Option.iter
    (fun v -> box##.style##.top := Js.string (Printf.sprintf "%ipx" v))
    top;
  Eliom_lib.Option.iter
    (fun v -> box##.style##.left := Js.string (Printf.sprintf "%ipx" v))
    left;
  Eliom_lib.Option.iter
    (fun v -> box##.style##.right := Js.string (Printf.sprintf "%ipx" v))
    right;
  Eliom_lib.Option.iter
    (fun v -> box##.style##.bottom := Js.string (Printf.sprintf "%ipx" v))
    bottom;
  Eliom_lib.Option.iter
    (fun v -> box##.style##.width := Js.string (Printf.sprintf "%ipx" v))
    width;
  Eliom_lib.Option.iter
    (fun v -> box##.style##.height := Js.string (Printf.sprintf "%ipx" v))
    height;
  Eliom_lib.Option.iter
    (fun a ->
       let bec = To_dom.of_element bec in
       match a with
       | `top i ->
         bec##.style##.top := Js.string "-11px";
         bec##.style##.left := Js.string (Printf.sprintf "%ipx" i);
         bec##.style##.borderBottom := Js.string "none";
         bec##.style##.borderRight := Js.string "none"
       | `left i ->
         bec##.style##.left := Js.string "-11px";
         bec##.style##.top := Js.string (Printf.sprintf "%ipx" i);
         bec##.style##.borderTop := Js.string "none";
         bec##.style##.borderRight := Js.string "none"
       | `bottom i ->
         bec##.style##.bottom := Js.string "-11px";
         bec##.style##.left := Js.string (Printf.sprintf "%ipx" i);
         bec##.style##.borderTop := Js.string "none";
         bec##.style##.borderLeft := Js.string "none"
       | `right i ->
         bec##.style##.right := Js.string "-11px";
         bec##.style##.top := Js.string (Printf.sprintf "%ipx" i);
         bec##.style##.borderBottom := Js.string "none";
         bec##.style##.borderLeft := Js.string "none"
    )
    arrow;
  Lwt.return ()

(* Function to be called on server to display a tip *)
let%shared bubble ?a ?arrow ?top ?left ?right ?bottom ?height ?width
    ?parent_node ~(name : string) ~content () =
  let myid_o = Eba_current_user.Opt.get_current_userid () in
  if myid_o = None
  then Lwt.return ()
  else
    let%lwt seen = get_tips_seen () in
    if Stringset.mem name seen
    then Lwt.return ()
    else let _ = [%client ( Lwt.async (fun () ->
              display_bubble ?a:~%a ?arrow:~%arrow
                ?top:~%top ?left:~%left ?right:~%right ?bottom:~%bottom
                ?height:~%height ?width:~%width
                ?parent_node:~%parent_node
                ~name:(~%name : string)
                ~content:~%content
                ())
                            : unit)]
      in
      Lwt.return ()
