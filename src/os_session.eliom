(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright 2014
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

[%%shared
  open Eliom_content.Html
  open Eliom_content.Html.F
]

let user_indep_state_hierarchy = Eliom_common.create_scope_hierarchy "userindep"
let user_indep_process_scope = `Client_process user_indep_state_hierarchy
let user_indep_session_scope = `Session user_indep_state_hierarchy

let new_process_eref =
  Eliom_reference.Volatile.eref
    ~scope:user_indep_process_scope
    true

(* Call this to add an action to be done on server side
   when the process starts *)
let (on_start_process, start_process_action) =
  let r = ref Lwt.return in
  ((fun f ->
      let oldf = !r in
      r := (fun () -> let%lwt () = oldf () in f ())),
   (fun () -> !r ()))

(* Call this to add an action to be done
   when the process starts in connected mode, or when the user logs in *)
let (on_start_connected_process, start_connected_process_action) =
  let r = ref (fun _ -> Lwt.return ()) in
  ((fun f ->
      let oldf = !r in
      r := (fun userid -> let%lwt () = oldf userid in f userid)),
   (fun userid -> !r userid))

(* Call this to add an action to be done at each connected request *)
let (on_connected_request, connected_request_action) =
  let r = ref (fun _ -> Lwt.return ()) in
  ((fun f ->
      let oldf = !r in
      r := (fun userid -> let%lwt () = oldf userid in f userid)),
   (fun userid -> !r userid))

(* Call this to add an action to be done just after openning a session *)
let (on_open_session, open_session_action) =
  let r = ref (fun _ -> Lwt.return ()) in
  ((fun f ->
      let oldf = !r in
      r := (fun userid -> let%lwt () = oldf userid in f userid)),
   (fun userid -> !r userid))

(* Call this to add an action to be done just after closing the session *)
let (on_post_close_session, post_close_session_action) =
  let r = ref (fun _ -> Lwt.return ()) in
  ((fun f ->
      let oldf = !r in
      r := (fun () -> let%lwt () = oldf () in f ())),
   (fun () -> !r ()))

(* Call this to add an action to be done just before closing the session *)
let (on_pre_close_session, pre_close_session_action) =
  let r = ref (fun _ -> Lwt.return ()) in
  ((fun f ->
      let oldf = !r in
      r := (fun () -> let%lwt () = oldf () in f ())),
   (fun () -> !r ()))

(* Call this to add an action to be done just before handling a request *)
let (on_request, request_action) =
  let r = ref (fun _ -> Lwt.return ()) in
  ((fun f ->
      let oldf = !r in
      r := (fun () -> let%lwt () = oldf () in f ())),
   (fun () -> !r ()))

(* Call this to add an action to be done just for each denied request *)
let (on_denied_request, denied_request_action) =
  let r = ref (fun _ -> Lwt.return ()) in
  ((fun f ->
      let oldf = !r in
      r := (fun userido -> let%lwt () = oldf userido in f userido)),
   (fun userido -> !r userido))


[%%shared
exception Not_connected
exception Permission_denied
]

let start_connected_process uid =
  (* We want to warn the client when the server side process state is closed.
     To do that, we listen on a channel and wait for exception. *)
  (* let c : unit Eliom_comet.Channel.t = *)
  (*   Eliom_comet.Channel.create (fst (Lwt_stream.create ())) *)
  (* in *)
  (* ignore {unit{ *)
  (*   Lwt.async *)
  (*     (fun () -> *)
  (*        Lwt.catch *)
  (*          (fun () -> Lwt_stream.iter_s (fun () -> Lwt.return ()) %c) *)
  (*          (function *)
  (*            | Eliom_comet.Process_closed -> close_client_process () *)
  (*            | e -> *)
  (*              Eliom_lib.debug_exn "comet exception: " e; *)
  (*              close_client_process () *)
  (*              (\* Lwt.fail e *\))) *)
  (* }}; *)
  start_connected_process_action uid

let connect_volatile uid =
  Eliom_state.set_volatile_data_session_group
    ~scope:Eliom_common.default_session_scope uid;
  let uid = Int64.of_string uid in
  open_session_action uid

let connect_string uid =
  let%lwt () = Eliom_state.set_persistent_data_session_group
    ~scope:Eliom_common.default_session_scope uid in
  let%lwt () = connect_volatile uid in
  let uid = Int64.of_string uid in
  start_connected_process uid

let connect ?(expire = false) userid =
  let%lwt () =
    if expire then begin
      let open Eliom_common in
      let cookie_scope = (default_session_scope :> cookie_scope) in
      Eliom_state.set_service_cookie_exp_date ~cookie_scope None;
      Eliom_state.set_volatile_data_cookie_exp_date ~cookie_scope None;
      Eliom_state.set_persistent_data_cookie_exp_date ~cookie_scope None
    end else
      Lwt.return ()
  in
  connect_string (Int64.to_string userid)

let disconnect () =
  let%lwt () = pre_close_session_action () in
  let%lwt () = Eliom_state.discard ~scope:Eliom_common.default_session_scope () in
  let%lwt () = Eliom_state.discard ~scope:Eliom_common.default_process_scope () in
  let%lwt () = Eliom_state.discard ~scope:Eliom_common.request_scope () in
  post_close_session_action ()

let check_allow_deny userid allow deny =
  let%lwt b = match allow with
    | None -> Lwt.return true (* By default allow all *)
    | Some l -> (* allow only users from one of the groups of list l *)
      Lwt_list.fold_left_s
        (fun b group ->
           let%lwt b2 = Os_group.in_group ~userid ~group in
           Lwt.return (b || b2)) false l
  in
  let%lwt b = match deny with
    | None -> Lwt.return b (* By default deny nobody *)
    | Some l -> (* allow only users that are not
                     in one of the groups of list l *)
      Lwt_list.fold_left_s
        (fun b group ->
           let%lwt b2 = Os_group.in_group ~userid ~group in
           Lwt.return (b && (not b2))) b l
  in
  if b then Lwt.return ()
  else begin
    let%lwt () = denied_request_action (Some userid) in
    Lwt.fail Permission_denied
  end


let get_session () =
  let uids = Eliom_state.get_volatile_data_session_group () in
  let get_uid uid =
    try Eliom_lib.Option.map Int64.of_string uid
    with Failure _ -> None
  in
  let%lwt uid = match get_uid uids with
    | None ->
      let%lwt uids = Eliom_state.get_persistent_data_session_group () in
      (match get_uid uids  with
       | Some uid ->
         (* A persistent session exists, but the volatile session has gone.
            It may be due to a timeout or may be the server has been
            relaunched.
            We restart the volatile session silently
            (comme si de rien n'était, pom pom pom). *)
         let%lwt () = connect_volatile (Int64.to_string uid) in
         Lwt.return (Some uid)
       | None -> Lwt.return None)
    | Some uid -> Lwt.return (Some uid)
  in
  (* Check if the user exists in the DB *)
  match uid with
  | None -> Lwt.return None
  | Some uid ->
    try%lwt
      let%lwt _user = Os_user.user_of_userid uid in
      Lwt.return (Some uid)
    with
    | Os_user.No_such_user ->
      (* If session exists and no user in DB, close the session *)
      let%lwt () = disconnect () in
      Lwt.return None

(** The connection wrapper checks whether the user is connected,
    and calls the page generator accordingly.
    It is usually recommended to have both a connected and non-connected
    version of each page. By default, the non-connected version
    will display a connection form.

    If connected, [gen_wrapper connected non_connected gp pp]
    calls the [connected] function given as parameters,
    taking user id, GET parameters [gp] and POST parameters [pp].

    If not, it calls the [not_connected] function.

    If we are launching a new client side process,
    functions [on_start_process] is called,
    and also [on_start_connected_process] if connected.

    If [allow] or [deny] are present, it will check that the user belongs
    or not to these groups, and call function [deny_fun] otherwise.
    By default, it raises [Permission_denied].
*)
let gen_wrapper ~allow ~deny
    ?(deny_fun = fun _ -> Lwt.fail Permission_denied)
    connected not_connected gp pp =
  let new_process = Eliom_reference.Volatile.get new_process_eref in
  let%lwt uid = get_session () in
  let%lwt () = request_action () in
  let%lwt () =
    if new_process
    then begin
      Eliom_reference.Volatile.set new_process_eref false;
      (* client side process:
         Now we want to do some computation only when we start a
         client side process. *)
      let%lwt () = start_process_action () in
      match uid with
      | None -> Lwt.return ()
      | Some id -> (* new client process, but already connected *)
        start_connected_process id
    end
    else Lwt.return ()
  in
  match uid with
  | None ->
    if allow = None
    then not_connected gp pp
    else let%lwt () = denied_request_action None in
      deny_fun None
  | Some id ->
    try%lwt
      let%lwt () = check_allow_deny id allow deny in
      let%lwt () = connected_request_action id in
      connected id gp pp
    with Permission_denied -> deny_fun uid

[%%client

   let get_current_userid_o = ref (fun () -> assert false)

(* On client-side, we do no security check.
   They are done by the server. *)
let gen_wrapper ~allow ~deny
    ?(deny_fun = fun _ -> Lwt.fail Permission_denied)
    connected not_connected gp pp =
  let userid_o = !get_current_userid_o () in
  match userid_o with
  | None -> not_connected gp pp
  | Some userid -> connected userid gp pp

]

[%%shared
let connected_fun ?allow ?deny ?deny_fun f gp pp =
  gen_wrapper
    ~allow ~deny ?deny_fun
    f
    (fun _ _ -> Lwt.fail Not_connected)
    gp pp

let connected_rpc ?allow ?deny ?deny_fun f pp =
  gen_wrapper
    ~allow ~deny ?deny_fun
    (fun userid _ p -> f userid p)
    (fun _ _ -> Lwt.fail Not_connected)
    () pp

let connected_wrapper ?allow ?deny ?deny_fun f pp =
  gen_wrapper
    ~allow ~deny ?deny_fun
    (fun userid _ p -> f p)
    (fun _ p -> f p)
    () pp

module Opt = struct

  let connected_fun ?allow ?deny ?deny_fun f gp pp =
    gen_wrapper
      ~allow ~deny ?deny_fun
      (fun userid gp pp -> f (Some userid) gp pp)
      (fun gp pp -> f None gp pp)
      gp pp

  let connected_rpc ?allow ?deny ?deny_fun f pp =
    gen_wrapper
      ~allow ~deny ?deny_fun
      (fun userid _ p -> f (Some userid) p)
      (fun _ p -> f None p)
      () pp

end

]
