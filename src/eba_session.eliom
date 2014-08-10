(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
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

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

{client{
  (* This will close the client process *)
  let close_client_process () =
    let d =
      D.div ~a:[a_class ["eba_process_closed"]] [
        img ~alt:("Ocsigen Logo")
          ~src:(Xml.uri_of_string ("http://ocsigen.org/resources/logos/ocsigen_with_shadow.png"))
          ();
        p [
          pcdata "Ocsigen process closed.";
          br ();
          a ~xhr:false
            ~service:Eliom_service.void_coservice'
            [pcdata "Click"]
            ();
          pcdata " to restart."
        ];
      ]
    in
    let d = To_dom.of_div d in
    Dom.appendChild (Dom_html.document##body) d;
    lwt () = Lwt_js_events.request_animation_frame () in
    d##style##backgroundColor <- Js.string "rgba(255, 255, 255, 0.7)";
    Lwt.return ()
}}


(* Call this to add an action to be done on server side
   when the process starts *)
let (on_start_process, start_process_action) =
  let r = ref Lwt.return in
  ((fun f ->
      let oldf = !r in
      r := (fun () -> lwt () = oldf () in f ())),
   (fun () -> !r ()))

(* Call this to add an action to be done
   when the process starts in connected mode, or when the user logs in *)
let (on_start_connected_process, start_connected_process_action) =
  let r = ref Lwt.return in
  ((fun f ->
      let oldf = !r in
      r := (fun () -> lwt () = oldf () in f ())),
   (fun () -> !r ()))

(* Call this to add an action to be done at each connected request *)
let (on_connected_request, connected_request_action) =
  let r = ref (fun _ -> Lwt.return ()) in
  ((fun f ->
      let oldf = !r in
      r := (fun userid -> lwt () = oldf userid in f userid)),
   (fun userid -> !r userid))

(* Call this to add an action to be done just after openning a session *)
let (on_open_session, open_session_action) =
  let r = ref (fun _ -> Lwt.return ()) in
  ((fun f ->
      let oldf = !r in
      r := (fun userid -> lwt () = oldf userid in f userid)),
   (fun userid -> !r userid))

(* Call this to add an action to be done just before closing the session *)
let (on_close_session, close_session_action) =
  let r = ref (fun _ -> Lwt.return ()) in
  ((fun f ->
      let oldf = !r in
      r := (fun () -> lwt () = oldf () in f ())),
   (fun () -> !r ()))

(* Call this to add an action to be done just before handling a request *)
let (on_request, request_action) =
  let r = ref (fun _ -> Lwt.return ()) in
  ((fun f ->
      let oldf = !r in
      r := (fun () -> lwt () = oldf () in f ())),
   (fun () -> !r ()))

(* Call this to add an action to be done just for each denied request *)
let (on_denied_request, denied_request_action) =
  let r = ref (fun _ -> Lwt.return ()) in
  ((fun f ->
      let oldf = !r in
      r := (fun userido -> lwt () = oldf userido in f userido)),
   (fun userido -> !r userido))



module Make
  (C : Eba_config.Session)
  (Groups : Eba_sigs.Groups)
=
struct
  include Eba_shared.Session

  type group = Groups.t

  exception Permission_denied

  let userid : int64 option Eliom_reference.Volatile.eref =
    (* This is a cache of current user *)
    Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope None

  (* SECURITY: We can trust these functions on server side,
     because the user is set at every request from the session cookie value.
     But do not trust a user sent by te client ...
  *)
  let get_current_userid () =
    match Eliom_reference.Volatile.get userid with
      | Some a -> a
      | None -> raise Eba_shared.Session.Not_connected

  (*VVV!!! I am not happy with these 2 functions set_user.
    If we forget to call them, the user will be wrong.
    get_current_user_or_fail could call User.user_of_uid itself
    but it does not work if we want to set the client side value ...
    For the client side value, we could use a wrapped reference but
    - the value must be set before wrapping, otherwise we will wrap a lwt
    thread ... We need a wrapper that waits the end of the server side threads
    and wrap the value it returns?
    - if they are sent only once, the value will be wrong because when
    the client side program starts, the value is None
    - if they are sent every request, it's too much, and this is probably
    not the right semantics for wrapping Eliom references

  *)
  let set_user_server uid =
    Eliom_reference.Volatile.set userid (Some uid);
    Lwt.return ()

  let unset_user_server () =
    Eliom_reference.Volatile.set userid None

  let set_user_client () =
    match Eliom_reference.Volatile.get userid with
      | None -> () (* Should never happen *)
      | Some userid ->
          ignore {unit{ Eba_shared.Session.set_current_userid %userid }}

  let unset_user_client () =
    ignore {unit{ Eba_shared.Session.unset_current_userid () }}

  let start_connected_process uid =
    let () = set_user_client () in
    (* We want to warn the client when the server side process state is closed.
       To do that, we listen on a channel and wait for exception. *)
    let c : unit Eliom_comet.Channel.t =
      Eliom_comet.Channel.create (fst (Lwt_stream.create ()))
    in
    ignore {unit{
      Lwt.async
        (fun () ->
           Lwt.catch
             (fun () -> Lwt_stream.iter_s (fun () -> Lwt.return ()) %c)
             (function
                | Eliom_comet.Process_closed ->
                    close_client_process ()
                | e ->
                    Eliom_lib.debug_exn "comet exception: " e;
                    Lwt.fail e))
    }};
    lwt () = C.on_start_connected_process uid in
    start_connected_process_action ()

  let connect_volatile uid =
    Eliom_state.set_volatile_data_session_group
      ~scope:Eliom_common.default_session_scope uid;
    let uid = Int64.of_string uid in
    lwt () = C.on_open_session uid in
    open_session_action uid

  let connect_string uid =
    lwt () = Eliom_state.set_persistent_data_session_group
      ~scope:Eliom_common.default_session_scope uid in
    lwt () = connect_volatile uid in
    let uid = Int64.of_string uid in
    start_connected_process uid

  let connect userid =
    lwt () = set_user_server userid in
    connect_string (Int64.to_string userid)

  let disconnect () =
    lwt () = C.on_close_session () in
    lwt () = close_session_action () in
    unset_user_client (); (*VVV!!! will affect only current tab!! *)
    unset_user_server (); (* ok this is a request reference *)
    Lwt.return ()

  let check_allow_deny userid allow deny =
    lwt b = match allow with
      | None -> Lwt.return true (* By default allow all *)
      | Some l -> (* allow only users from one of the groups of list l *)
        Lwt_list.fold_left_s
          (fun b group ->
            lwt b2 = Groups.in_group ~userid ~group in
            Lwt.return (b || b2)) false l
    in
    lwt b = match deny with
      | None -> Lwt.return b (* By default deny nobody *)
      | Some l -> (* allow only users that are not
                     in one of the groups of list l *)
        Lwt_list.fold_left_s
          (fun b group ->
            lwt b2 = Groups.in_group ~userid ~group in
            Lwt.return (b && (not b2))) b l
    in
    if b then Lwt.return ()
    else begin
      lwt () = C.on_denied_request userid in
      lwt () = denied_request_action (Some userid) in
      Lwt.fail Permission_denied
    end


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
    let new_process = Eliom_request_info.get_sp_client_appl_name () = None in
    let uids = Eliom_state.get_volatile_data_session_group () in
    let get_uid uid =
      try
        match uid with
          | None -> None
          | Some u -> Some (Int64.of_string u)
      with Failure _ -> None
    in
    lwt uid = match get_uid uids with
      | None ->
        lwt uids = Eliom_state.get_persistent_data_session_group () in
        (match get_uid uids  with
          | Some uid ->
            (* A persistent session exists, but the volatile session has gone.
               It may be due to a timeout or may be the server has been
               relaunched.
               We restart the volatile session silently
               (comme si de rien n'était, pom pom pom). *)
            lwt () = set_user_server uid in
            (* We record the user info on server side
               as a request reference.
               As it is computed from the session cookie,
               it is safe on server side. *)
            lwt () = connect_volatile (Int64.to_string uid) in
            Lwt.return (Some uid)
          | None -> Lwt.return None)
      | Some uid ->
        lwt () = set_user_server uid in
        Lwt.return (Some uid)
    in
    lwt () =
      if new_process
      then begin
        (* client side process:
           Now we want to do some computation only when we start a
           client side process. *)
        lwt () = C.on_start_process () in
        lwt () = start_process_action () in
        match uid with
          | None -> Lwt.return ()
          | Some id -> (* new client process, but already connected *)
            start_connected_process id
      end
      else Lwt.return ()
    in
    lwt () = C.on_request () in
    lwt () = request_action () in
    match uid with
      | None ->
        if allow = None
        then not_connected gp pp
        else lwt () = denied_request_action None in
             deny_fun None
      | Some id ->
        try_lwt
          lwt () = check_allow_deny id allow deny in
          lwt () = C.on_connected_request id in
          lwt () = connected_request_action id in
          connected id gp pp
        with Permission_denied -> deny_fun uid

  let connected_fun ?allow ?deny ?deny_fun f gp pp =
    gen_wrapper
      ~allow ~deny ?deny_fun
      f
      (fun _ _ -> Lwt.fail Eba_shared.Session.Not_connected)
      gp pp

  let connected_rpc ?allow ?deny ?deny_fun f pp =
    gen_wrapper
      ~allow ~deny ?deny_fun
      (fun userid _ p -> f userid p)
      (fun _ _ -> Lwt.fail Eba_shared.Session.Not_connected)
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

    let get_current_userid () =
      Eliom_reference.Volatile.get userid
  end
end
