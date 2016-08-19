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


(*****************************************************************************)
(* We use a hashtable associating resourceid to a weak set of
   (userid option, notif_ev) corresponding to each tab that want to
   get updates of this box.
   We keep a strong reference on these data in process state.

   We also record all opened mainboxes.
*)

module Make (A : sig type key type notification end) = struct
  module Notif_hastbl =
    Hashtbl.Make(struct type t = A.key
      let equal = (=)
      let hash = Hashtbl.hash
    end)

  module Weak_tbl =
    Weak.Make(struct
      type t =
        (int64 option *
         ((A.key * A.notification) Eliom_react.Down.t *
          (A.key * A.notification) React.event *
          (?step:React.step -> (A.key * A.notification) -> unit))) option
      let equal a b = match a, b with
        | None, None -> true
        | Some (a, b), Some (c, d) -> a = c && b == d
        | _ -> false
      let hash = Hashtbl.hash
    end)

  module I = struct
    let tbl = Notif_hastbl.create 1000

    let remove v key =
      try let wt = Notif_hastbl.find tbl key in
        Weak_tbl.remove wt v;
        if Weak_tbl.count wt = 0
        then Notif_hastbl.remove tbl key
      with Not_found -> ()

    let add v key =
      let wt = try Notif_hastbl.find tbl key
        with Not_found -> let wt = Weak_tbl.create 10 in
          Notif_hastbl.add tbl key wt;
          wt
      in
      if not (Weak_tbl.mem wt v)
      then Weak_tbl.add wt v

    let fold f key beg =
      try let wt = Notif_hastbl.find tbl key in
        Weak_tbl.fold
          (fun r beg -> match r with
             | None -> remove r key; beg
             | Some v -> f v beg)
          wt beg
      with Not_found -> beg
  end

  let userchannel = (*VVV volatile??? *)
    Eliom_reference.Volatile.eref
      ~scope:Os_session.user_indep_process_scope None

(*VVV I duplicate the ref here because I want to be able to access
  the value when I iterate on the default hierachy (all tabs of a user).
  But this is probably not the right way to do that.
  How to fix that in Eliom?

VVV See if it is still needed
*)
  let userchannel2 = (*VVV volatile??? *)
    Eliom_reference.Volatile.eref
      ~scope:Eliom_common.default_process_scope None

  (* notif_e consists in a server side react event,
     its client side counterpart,
     and the server side function to trigger it. *)
  let notif_e :
    ('a * (A.key * A.notification) React.event * 'c)
      Eliom_reference.Volatile.eref =
    Eliom_reference.Volatile.eref_from_fun
      ~scope:Eliom_common.default_process_scope
      (fun () ->
         let e, send_e = React.E.create () in
         let client_ev = Eliom_react.Down.of_react
             (*VVV If we add throttling, some events may be lost
               even if buffer size is not 1 :O *)
             ~size: 100 (*VVV ? *)
             ~scope:Eliom_common.default_process_scope e in
         (client_ev, e, send_e)
         (* I don't really need e, but I need to keep a reference on it during
            the session to avoid it beeing garbage collected. *))

  let set_userchannel_ userid_o =
    (* For each tab connected to the app,
       we keep a pointer to (userid_o, notif_ev) option in process state,
       because the table resourceid -> (userid_o, notif_ev) option
       is weak.
    *)
    let a = Some (userid_o, Eliom_reference.Volatile.get notif_e) in
    Eliom_reference.Volatile.set userchannel a;
    Eliom_reference.Volatile.set userchannel2 a;
    Lwt.return ()

  let set_userchannel () =
    let userid_o = Os_current_user.Opt.get_current_userid () in
    set_userchannel_ userid_o

  let set_userchannel_u userid = set_userchannel_ (Some userid)

  let set_userchannel_none () = set_userchannel_ None

  let _ =
    Os_session.on_start_process set_userchannel;
    Os_session.on_start_connected_process set_userchannel_u;
    Os_session.on_post_close_session set_userchannel_none


  let listen (id : A.key) =
    let uc = Eliom_reference.Volatile.get userchannel in
    I.add uc id

  let unlisten (id : A.key) =
    let uc = Eliom_reference.Volatile.get userchannel in
    I.remove uc id

  let notify ?(notforme = false) id content_gen =
    Lwt.async (fun () ->
      I.fold (* on all tabs registered on this data *)
        (fun (userid_o, ((_, _, send_e) as nn)) (beg : unit Lwt.t) ->
           if notforme && nn == Eliom_reference.Volatile.get notif_e
           then Lwt.return ()
           else
             let%lwt () = beg in
             let%lwt content = content_gen userid_o in
             match content with
             | Some content -> send_e (id, content); Lwt.return ()
             | None -> Lwt.return ())
        id
        (Lwt.return ()))

  let client_ev () =
    let (ev, _, _) = Eliom_reference.Volatile.get notif_e in
    ev


end
