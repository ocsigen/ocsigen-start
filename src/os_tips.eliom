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

open%shared Eliom_content.Html
open%shared Eliom_content.Html.F
open%client Js_of_ocaml
open%client Js_of_ocaml_lwt
module%shared Stringset = Set.Make(String)

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

(* In the current version of Eliom (2016-09),
   groups of session have a weird semantics when no group is set
   (1 group per IP address if I remember).
   I think it would be better to have one group per session.
   At least group references (like tips_seen) would work and the user would
   have its tips.
   (If the sessions are not grouped together, then each group contain one
   session, which make more sense than grouping by IP address).

   For now, I'm using a session reference for not connected users ...
*)
let tips_seen_not_connected =
  Eliom_reference.eref
    ~persistent:"tips_seen_not_connected1"
    ~scope:Os_session.user_indep_session_scope
    Stringset.empty


(* We cache the set during a request *)
let seen_by_user =
  Eliom_reference.Volatile.eref_from_fun
    ~scope:Eliom_common.request_scope
    (fun () ->
       match Os_current_user.Opt.get_current_userid () with
       | None -> Eliom_reference.get tips_seen_not_connected
       | _ -> Eliom_reference.get tips_seen)

(* Get the set of seen tips *)
let%server get_tips_seen () = Eliom_reference.Volatile.get seen_by_user

(* We cache the set of seen tips to avoid doing the request several times.
   Warning: it is not updated if the user is using several devices or
   tabs at a time which means that the user may see the same tip several
   times in that case. *)
let%client tips_seen_client_ref = ref Stringset.empty
let%client get_tips_seen () = Lwt.return !tips_seen_client_ref

let%server () = Os_session.on_start_connected_process
    (fun _ ->
       let%lwt tips = get_tips_seen () in
       ignore [%client (
         tips_seen_client_ref := ~%tips
       : unit)];
       Lwt.return_unit)

(* notify the server that a user has seen a tip *)
let set_tip_seen (name : string) =
  let%lwt prev = Eliom_reference.Volatile.get seen_by_user in
  let newset = Stringset.add (name : string) prev in
  match Os_current_user.Opt.get_current_userid () with
  | None -> Eliom_reference.set tips_seen_not_connected newset
  | _ -> Eliom_reference.set tips_seen newset

let%client set_tip_seen name =
  tips_seen_client_ref := Stringset.add name !tips_seen_client_ref;
  ~%(Eliom_client.server_function
       ~name:"Os_tips.set_tip_seen"
       [%json: string]
       (Os_session.connected_wrapper set_tip_seen))
  name

(* counterpart of set_tip_seen *)
let unset_tip_seen name  =
  let%lwt prev = Eliom_reference.Volatile.get seen_by_user in
  let newset = Stringset.remove name prev in
  match Os_current_user.Opt.get_current_userid () with
  | None -> Eliom_reference.set tips_seen_not_connected newset
  | _ -> Eliom_reference.set tips_seen newset

let%client unset_tip_seen name =
  tips_seen_client_ref := Stringset.remove name !tips_seen_client_ref;
  ~%(Eliom_client.server_function
       ~name:"Os_tips.unset_tip_seen"
       [%json: string]
       (Os_session.connected_wrapper set_tip_seen))
    name

let%shared tip_seen name =
  let%lwt seen = get_tips_seen () in
  Lwt.return @@ Stringset.mem name seen

(* I want to see the tips again *)
let%server reset_tips_user myid_o =
  match myid_o with
  | None -> Eliom_reference.set tips_seen_not_connected (Stringset.empty)
  | _ -> Eliom_reference.set tips_seen (Stringset.empty)

let reset_tips () =
  reset_tips_user (Os_current_user.Opt.get_current_userid ())

let%server reset_tips_service =
  Eliom_service.create
    ~name:"resettips"
    ~path:Eliom_service.No_path
    ~meth:
      (Eliom_service.Post (Eliom_parameter.unit, Eliom_parameter.unit))
    ()

let%client reset_tips_service = ~%reset_tips_service

let%server _ =
  Eliom_registration.Action.register
    ~service:reset_tips_service
    (Os_session.Opt.connected_fun (fun myid_o () () -> reset_tips_user myid_o))

let%client reset_tips () =
  tips_seen_client_ref := Stringset.empty;
  ~%(Eliom_client.server_function
       ~name:"Os_tips.reset_tips"
       [%json: unit]
       (Os_session.connected_wrapper reset_tips))
    ()

(* Returns a block containing a tip,
   if it has not already been seen by the user. *)
let%shared block ?(a = []) ?(recipient = `All)
      ?(onclose = [%client (fun () -> Lwt.return_unit : unit -> unit Lwt.t)])
      ~name ~content () =
  let myid_o = Os_current_user.Opt.get_current_userid () in
  match recipient, myid_o with
  | `All, _
  | `Not_connected, None
  | `Connected, Some _ ->
    let%lwt seen = get_tips_seen () in
    if Stringset.mem name seen
    then Lwt.return_none
    else begin
      let box_ref = ref None in
      let close : (unit -> unit Lwt.t) Eliom_client_value.t =
        [%client (fun () ->
          let%lwt () = ~%onclose () in
          let () = match !(~%box_ref) with
            | Some x -> Manip.removeSelf x
            | None -> () in
          set_tip_seen ~%name)
        ]
      in
      let%lwt c = content close in
      let c = [ div ~a:[a_class [ "os-tip-content" ]] c ] in
      let box =
        D.div ~a:(a_class [ "os-tip" ; "os-tip-block" ]::a)
          (Os_icons.D.close ~a:[ a_class [ "os-tip-close" ]
                               ; a_onclick [%client fun _ ->
             Lwt.async ~%close ] ] ()
           :: c)
      in
      box_ref := Some box ;
      Lwt.return_some (box)
    end
  | _ -> Lwt.return_none

let%client onload_waiter () =
  let%lwt _  = Eliom_client.lwt_onload () in Lwt.return_unit

(* This list of threads is used to display only one tip at a time,
   in the order specified by the given priorities *)
let%client prioritized_waiters : (int option * unit Lwt.t * bool) list ref =
  ref []

(* [Lwt.cancel] does nothing if the task is already resolved,
   so we can safely cancel them all *)
let%client cancel_waiters () =
  List.iter (fun (_,w,_) -> Lwt.cancel w) !prioritized_waiters

(* This boolean is used to track whether
   the list of priorities has been sorted
 *)
let%client sorted = ref false

(* A priority of [None] is considered infinite,
   and thus greater than everything else *)
let%client compare_priority_opt p1 p2 =
  match p1,p2 with
  | None, None -> 0
  | None, _ -> 1
  | Some _, None -> -1
  | Some p1, Some p2 -> compare p1 p2

(* Find the appropriate promise to wait for
   corresponding to the given priority.

   This function assumes the input list is sorted.

   It turns to 'true' any priority item matched with its previous waiter.
   That much is useful to keep track of which items to ignore.

   It returns [None] if no appropriate promise is found.
   Otherwise it returns [Some (promise,l)]
   where [l] is meant to replace [prioritized_waiters]
   and [promise] is the promise the bubble calling the function should wait for.
 *)
let%client rec find_previous priority = function
  | [] -> (* Not found in an empty list *) None
  | (p,_,_)::_ when compare_priority_opt p priority > 0 ->
    (* First priority is too low: Not Found *)
    None
  | (p,w,false)::l when p = priority ->
    (* Very first priority found: Result waiter resolves immediately. *)
    Some (Lwt.return_unit, (p,w,true)::l)
  | (prevp, prevw, prevb)::(p,w,false)::tl
       when p = priority ->
    (* First of a series of priorities is available:
       Result waiter is the previous in the queue *)
    Some (prevw, (prevp,prevw,prevb)::(p,w,true)::tl)
  | (prevp, prevw, prevb)::(p,w,true)::tl
       when p = priority ->
    (* First of a series of priorities is unavailable:
       Keep looking and rebuild on top of the list *)
    (match find_previous priority ((p,w,true)::tl) with
     | None -> None
     | Some (r,l) -> Some (r, (prevp,prevw,prevb)::l))
  | (p,w,b)::l
       when compare_priority_opt p priority < 0 ->
    (* Following priority is not matched by previous cases:
       Keep looking and rebuild on top of the list *)
    (match find_previous priority l with
     | None -> None
     | Some (r,l) -> Some (r, (p,w,b)::l))
  | _ ->
    (* Catch-all because everything else uses guards,
       but should be unreachable *)
    assert false

let%client wait_for_bubble ?priority () =
  (* We wait for the elements to load,
     to be sure we have all waiters prioritized *)
  let%lwt () = onload_waiter () in
  if not !sorted then
    (prioritized_waiters :=
       List.rev @@ List.stable_sort
                     (fun (p1,_,_) (p2,_,_) -> -compare_priority_opt p1 p2)
                     !prioritized_waiters;
     sorted := true);
  match find_previous priority !prioritized_waiters with
  | None -> Lwt.return_unit
  | Some (w,l) -> prioritized_waiters := l; w

(* Registering a prioritized bubble. The list is sorted in decreasing order,
   and is meant to be reversed later. This is because order of
   lwt waiter additions are in reverse order from the order of calls to
   Os_tips.bubble. *)
let%client register_bubble ?priority w =
  match priority with
  | None -> prioritized_waiters := !prioritized_waiters @ [(priority,w, false)]
  | Some p ->
    prioritized_waiters := (priority,w, false)::!prioritized_waiters

let%client rec onchangepage_handler _ =
  cancel_waiters ();
  sorted := false;
  prioritized_waiters := [];
  (* onchangepage handlers are one-off, register ourselves again for
     next time *)
  Eliom_client.onchangepage onchangepage_handler;
  Lwt.return_unit

let%client () = Eliom_client.onchangepage onchangepage_handler

(* Display a tip bubble *)
let%client display_bubble ?(a = [])
    ?arrow ?top ?left ?right ?bottom ?height ?width
    ?(parent_node : _ elt option) ?(delay = 0.0) ?priority ?(onclose = fun () -> Lwt.return_unit)
    ~name ~content ()
  =
  let new_waiter, new_wakener = Lwt.task () in
  register_bubble ?priority new_waiter;
  let%lwt () = wait_for_bubble ?priority () in
  let bec = D.div ~a:[a_class ["os-tip-bec"]] [] in
  let box_ref = ref None in
  let close = fun () ->
    let%lwt () = onclose () in
    let () = match !box_ref with
      | Some x -> Manip.removeSelf x
      | None -> () in
    Lwt.wakeup new_wakener ();
    set_tip_seen (name : string) in
  let%lwt c = content close in
  let c = [ div ~a:[a_class [ "os-tip-content" ]] c ] in
  let box =
    D.div ~a:(a_class [ "os-tip" ; "os-tip-bubble" ]::a)
      (Os_icons.D.close ~a:[ a_class [ "os-tip-close" ]
                           ; a_onclick (fun _ -> Lwt.async close) ] ()
       :: match arrow with None -> c
                         | _    -> bec :: c)
  in
  box_ref := Some box ;
  let parent_node = match parent_node with
    | None -> Dom_html.document##.body
    | Some p -> To_dom.of_element p
  in
  let%lwt () = Ot_nodeready.nodeready parent_node in
  let%lwt () = Lwt_js.sleep delay in
  let box = To_dom.of_element box in
  Dom.appendChild parent_node box;
  box##.style##.opacity := Js.def (Js.string "0");
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
       let bec_size = bec##.offsetWidth in
       let offset = Printf.sprintf "-%dpx" (bec_size / 2) in
       match a with
       | `top i ->
         bec##.style##.top := Js.string offset;
         bec##.style##.left := Js.string (Printf.sprintf "%ipx" i);
         bec##.style##.borderBottom := Js.string "none";
         bec##.style##.borderRight := Js.string "none"
       | `left i ->
         bec##.style##.left := Js.string offset;
         bec##.style##.top := Js.string (Printf.sprintf "%ipx" i);
         bec##.style##.borderTop := Js.string "none";
         bec##.style##.borderRight := Js.string "none"
       | `bottom i ->
         bec##.style##.bottom := Js.string offset;
         bec##.style##.left := Js.string (Printf.sprintf "%ipx" i);
         bec##.style##.borderTop := Js.string "none";
         bec##.style##.borderLeft := Js.string "none"
       | `right i ->
         bec##.style##.right := Js.string offset;
         bec##.style##.top := Js.string (Printf.sprintf "%ipx" i);
         bec##.style##.borderBottom := Js.string "none";
         bec##.style##.borderLeft := Js.string "none"
    )
    arrow;
  let%lwt () = Lwt_js_events.request_animation_frame () in
  box##.style##.opacity := Js.def (Js.string "1");
  Lwt.return_unit

(* Function to be called on server to display a tip *)
let%shared bubble
  ?(a: [< Html_types.div_attrib > `Class ] Eliom_content.Html.D.attrib list
  option)
  ?(recipient = `All)
  ?(arrow: [< `left of int
          | `right of int
          | `top of int
          | `bottom of int ] Eliom_client_value.t option)
  ?(top: int Eliom_client_value.t option)
  ?(left: int Eliom_client_value.t option)
  ?(right: int Eliom_client_value.t option)
  ?(bottom: int Eliom_client_value.t option)
  ?(height: int Eliom_client_value.t option)
  ?(width: int Eliom_client_value.t option)
  ?(parent_node: [< `Body | Html_types.body_content ] Eliom_content.Html.elt
        option)
  ?delay
  ?(priority : int option)
  ?onclose
  ~(name : string)
  ~(content:
      ((unit -> unit Lwt.t)
       -> Html_types.div_content Eliom_content.Html.elt list Lwt.t)
        Eliom_client_value.t)
  () =
  let delay : float option = delay in
  let onclose : (unit -> unit Lwt.t) Eliom_client_value.t option = onclose in
  let myid_o = Os_current_user.Opt.get_current_userid () in
  match recipient, myid_o with
  | `All, _
  | `Not_connected, None
  | `Connected, Some _ ->
    let%lwt seen = get_tips_seen () in
    if Stringset.mem name seen
    then Lwt.return_unit
    else let _ = [%client ( Lwt.async (fun () ->
      display_bubble ?a:~%a ?arrow:~%arrow
        ?top:~%top ?left:~%left ?right:~%right ?bottom:~%bottom
        ?height:~%height ?width:~%width
        ?parent_node:~%parent_node
        ?delay:~%delay ?priority:~%priority
        ?onclose:~%onclose
        ~name:(~%name : string)
        ~content:~%content
        ())
                            : unit)]
      in
      Lwt.return_unit
  | _ -> Lwt.return_unit
