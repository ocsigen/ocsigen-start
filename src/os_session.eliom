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

open Lwt.Syntax

let log_section = Lwt_log.Section.make "os:session"
let user_indep_state_hierarchy = Eliom_common.create_scope_hierarchy "userindep"
let user_indep_process_scope = `Client_process user_indep_state_hierarchy
let user_indep_session_scope = `Session user_indep_state_hierarchy

(* We make it possible to acces the user_indep scope from connected scope *)
let current_user_indep_session_state =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.default_session_scope None

let new_process_eref =
  Eliom_reference.Volatile.eref ~scope:user_indep_process_scope true

let mk_action_queue name =
  let r = ref (fun _ -> Lwt.return_unit) in
  ( (fun f ->
      let oldf = !r in
      r :=
        fun arg ->
          let* () = oldf arg in
          f arg)
  , fun arg ->
      Lwt_log.ign_debug ~section:log_section ("handling actions: " ^ name);
      !r arg )

let on_connected_request, connected_request_action =
  mk_action_queue "connected request"

let on_unconnected_request, unconnected_request_action =
  mk_action_queue "unconnected request"

let on_open_session, open_session_action = mk_action_queue "open session"

let on_post_close_session, post_close_session_action =
  mk_action_queue "post close session"

let on_pre_close_session, pre_close_session_action =
  mk_action_queue "pre close session"

let on_request, request_action = mk_action_queue "request"
let on_denied_request, denied_request_action = mk_action_queue "denied request"
let on_start_process, start_process_action = mk_action_queue "start process"

let on_start_connected_process f =
  on_start_process (fun myid_o ->
    match myid_o with Some myid -> f myid | None -> Lwt.return_unit)

let on_start_unconnected_process f =
  on_start_process (fun myid_o ->
    match myid_o with Some _myid -> Lwt.return_unit | None -> f ())

[%%shared
exception Not_connected
exception Permission_denied]

let connect_volatile uid =
  Eliom_state.set_volatile_data_session_group
    ~scope:Eliom_common.default_session_scope uid;
  let uid = Int64.of_string uid in
  Eliom_reference.Volatile.set current_user_indep_session_state
    (Some
       (Eliom_state.Ext.current_volatile_data_state
          ~scope:user_indep_session_scope ()));
  open_session_action uid

let connect_string uid =
  let* () =
    Eliom_state.set_persistent_data_session_group
      ~scope:Eliom_common.default_session_scope uid
  in
  let* () = connect_volatile uid in
  let uid = Int64.of_string uid in
  start_process_action (Some uid)

let disconnect () =
  let* () = pre_close_session_action () in
  let* () = Eliom_state.discard ~scope:Eliom_common.default_session_scope () in
  let* () = Eliom_state.discard ~scope:Eliom_common.default_process_scope () in
  let* () = Eliom_state.discard ~scope:Eliom_common.request_scope () in
  post_close_session_action ()

let connect ?(expire = false) userid =
  let* () = disconnect () in
  let* () =
    if expire
    then (
      let open Eliom_common in
      let cookie_scope = (default_session_scope :> cookie_scope) in
      Eliom_state.set_service_cookie_exp_date ~cookie_scope None;
      Eliom_state.set_volatile_data_cookie_exp_date ~cookie_scope None;
      Eliom_state.set_persistent_data_cookie_exp_date ~cookie_scope None)
    else Lwt.return_unit
  in
  connect_string (Int64.to_string userid)

let set_warn_connection_change, warn_connection_changed =
  let r = ref (fun _ -> ()) in
  (fun f -> r := f), fun state -> !r state; Lwt.return_unit

let disconnect_all
      ?sitedata
      ?userid
      ?(user_indep = true)
      ?(with_restart = true)
      ()
  =
  let close_my_sessions = userid = None in
  let* () =
    if close_my_sessions then pre_close_session_action () else Lwt.return_unit
  in
  let userid =
    match userid with
    | None -> (
        let uid = Eliom_state.get_volatile_data_session_group () in
        try Eliom_lib.Option.map Int64.of_string uid with Failure _ -> None)
    | Some userid -> Some userid
  in
  match userid with
  | None -> Lwt.return_unit
  | Some userid ->
      (* We do not close the group, as it may contain user data.
       We close all sessions from group instead. *)
      let group_name = Int64.to_string userid in
      let states =
        [ Eliom_state.Ext.volatile_data_group_state
            ~scope:Eliom_common.default_group_scope group_name
        ; Eliom_state.Ext.persistent_data_group_state
            ~scope:Eliom_common.default_group_scope group_name
        ; Eliom_state.Ext.service_group_state
            ~scope:Eliom_common.default_group_scope group_name ]
      in
      let* ui_states =
        List.fold_left
          (fun acc state ->
             Lwt.bind
               (Eliom_reference.Ext.get state
                  (current_user_indep_session_state
                    :> ( [< `Session_group | `Session | `Client_process]
                         , [< `Data | `Pers] )
                         Eliom_state.Ext.state
                         option
                         Eliom_reference.eref))
               (function
                 | None -> acc
                 | Some s ->
                     let* acc = acc in
                     Lwt.return (s :: acc)))
          Lwt.return_nil
          (Eliom_state.Ext.fold_volatile_sub_states ?sitedata
             ~state:
               (Eliom_state.Ext.volatile_data_group_state
                  ~scope:Eliom_common.default_group_scope group_name)
             (fun acc s -> s :: acc)
             [])
      in
      let*
          (* Closing all sessions: *)
            ()
        =
        Lwt_list.iter_s
          (fun state ->
             Eliom_state.Ext.iter_sub_states ?sitedata ~state @@ fun state ->
             Eliom_state.Ext.discard_state ?sitedata ~state ())
          states
      in
      let* () =
        if close_my_sessions
        then post_close_session_action ()
        else Lwt.return_unit
      in
      let*
          (* Warn every client process that the session is closed: *)
            ()
        =
        Lwt_list.iter_s
          (fun state ->
             Eliom_state.Ext.iter_sub_states ?sitedata ~state
               warn_connection_changed)
          ui_states
      in
      let*
          (* Closing user_indep states, if requested: *)
            ()
        =
        if user_indep
        then
          Lwt_list.iter_s
            (fun state -> Eliom_state.Ext.discard_state ?sitedata ~state ())
            ui_states
        else Lwt.return_unit
      in
      let () =
        if with_restart then ignore [%client (Os_handlers.restart () : unit)]
      in
      Lwt.return_unit

let check_allow_deny userid allow deny =
  let* b =
    match allow with
    | None -> Lwt.return_true (* By default allow all *)
    | Some l ->
        (* allow only users from one of the groups of list l *)
        Lwt_list.fold_left_s
          (fun b group ->
             let* b2 = Os_group.in_group ~userid ~group () in
             Lwt.return (b || b2))
          false l
  in
  let* b =
    match deny with
    | None -> Lwt.return b (* By default deny nobody *)
    | Some l ->
        (* allow only users that are not
                     in one of the groups of list l *)
        Lwt_list.fold_left_s
          (fun b group ->
             let* b2 = Os_group.in_group ~userid ~group () in
             Lwt.return (b && not b2))
          b l
  in
  if b
  then Lwt.return_unit
  else
    let* () = denied_request_action (Some userid) in
    Lwt.fail Permission_denied

let get_session () =
  let uids = Eliom_state.get_volatile_data_session_group () in
  let get_uid uid =
    try Eliom_lib.Option.map Int64.of_string uid with Failure _ -> None
  in
  let* uid =
    match get_uid uids with
    | None -> (
        let* uids = Eliom_state.get_persistent_data_session_group () in
        match get_uid uids with
        | Some uid ->
            let*
                (* A persistent session exists, but the volatile session has gone.
            It may be due to a timeout or may be the server has been
            relaunched.
            We restart the volatile session silently
            (comme si de rien n'était, pom pom pom). *)
                  ()
              =
              connect_volatile (Int64.to_string uid)
            in
            Lwt.return_some uid
        | None -> Lwt.return_none)
    | Some uid -> Lwt.return_some uid
  in
  (* Check if the user exists in the DB *)
  match uid with
  | None -> Lwt.return_none
  | Some uid ->
      Lwt.catch
        (fun () ->
           let* _user = Os_user.user_of_userid uid in
           Lwt.return_some uid)
        (function
          | Os_user.No_such_user ->
              let*
                  (* If session exists and no user in DB, close the session *)
                    ()
                =
                disconnect ()
              in
              Lwt.return_none
          | exc -> Lwt.reraise exc)

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
let%server
    gen_wrapper
      ~allow
      ~deny
      ?(force_unconnected = false)
      ?(deny_fun = fun _ -> Lwt.fail Permission_denied)
      connected
      not_connected
      gp
      pp
  =
  let new_process =
    (not force_unconnected) && Eliom_reference.Volatile.get new_process_eref
  in
  let* uid = if force_unconnected then Lwt.return_none else get_session () in
  let* () = request_action uid in
  let* () =
    if new_process
    then (
      Eliom_reference.Volatile.set new_process_eref false;
      start_process_action uid)
    else Lwt.return_unit
  in
  match uid with
  | None ->
      if allow = None
      then
        let* () = unconnected_request_action () in
        not_connected gp pp
      else
        let* () = denied_request_action None in
        deny_fun None
  | Some id ->
      Lwt.catch
        (fun () ->
           let* () = check_allow_deny id allow deny in
           let* () = connected_request_action id in
           connected id gp pp)
        (function Permission_denied -> deny_fun uid | exc -> Lwt.reraise exc)

let%client get_current_userid_o = ref (fun () -> assert false)

(* On client-side, we do no security check.
   They are done by the server. *)
let%client
    gen_wrapper
      ~allow:_
      ~deny:_
      ?(force_unconnected = false)
      ?deny_fun:_
      connected
      not_connected
      gp
      pp
  =
  let myid_o = if force_unconnected then None else !get_current_userid_o () in
  match myid_o with
  | None -> not_connected gp pp
  | Some myid -> connected myid gp pp

let%shared connected_fun ?allow ?deny ?deny_fun f gp pp =
  gen_wrapper ~allow ~deny ?deny_fun f (fun _ _ -> Lwt.fail Not_connected) gp pp

let%shared connected_rpc ?allow ?deny ?deny_fun f pp =
  gen_wrapper ~allow ~deny ?deny_fun
    (fun myid _ p -> f myid p)
    (fun _ _ -> Lwt.fail Not_connected)
    () pp

let%shared connected_wrapper ?allow ?deny ?deny_fun ?force_unconnected f pp =
  gen_wrapper ?force_unconnected ~allow ~deny ?deny_fun
    (fun _myid _ p -> f p)
    (fun _ p -> f p)
    () pp

[%%shared
module Opt = struct
  let connected_fun ?allow ?deny ?deny_fun ?force_unconnected f gp pp =
    gen_wrapper ?force_unconnected ~allow ~deny ?deny_fun
      (fun myid gp pp -> f (Some myid) gp pp)
      (fun gp pp -> f None gp pp)
      gp pp

  let connected_rpc ?allow ?deny ?deny_fun ?force_unconnected f pp =
    gen_wrapper ?force_unconnected ~allow ~deny ?deny_fun
      (fun myid _ p -> f (Some myid) p)
      (fun _ p -> f None p)
      () pp
end]

let%client disconnect =
  ~%(Eliom_client.server_function ~name:"Os_session.disconnect" [%json: unit]
       (connected_wrapper disconnect))

let%client disconnect_all ?(user_indep = true) () =
  ~%(Eliom_client.server_function ~name:"Os_session.disconnect_all"
       [%json: bool]
       (connected_wrapper (fun user_indep -> disconnect_all ~user_indep ())))
    user_indep
