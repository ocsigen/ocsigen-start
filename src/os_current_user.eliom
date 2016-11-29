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

let section = Lwt_log.Section.make "os:current_user"

[%%shared
  type current_user =
    | CU_idontknown
    | CU_notconnected
    | CU_user of Os_types.User.t
]

let%shared please_use_connected_fun =
  "Os_current_user is usable only with connected functions"


(* current user *)
let me : current_user Eliom_reference.Volatile.eref =
  (* This is a request cache of current user *)
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope CU_idontknown

let%client me : current_user ref = ref CU_notconnected
  (*on client side the default is not connected *)

let%client get_current_user_option () =
  match !me with
  | CU_idontknown -> assert false
  | CU_notconnected -> None
  | CU_user u -> Some u

let%client get_current_user () =
  match !me with
  | CU_user a -> a
  | CU_idontknown -> (* Should never happen *) failwith please_use_connected_fun
  | _ ->
    Firebug.console##(log (Js.string "Not connected error in Os_current_user"));
    raise Os_session.Not_connected

(* SECURITY: We can trust these functions on server side,
   because the user is set at every request from the session cookie value.
   But do not trust a user sent by the client ...
*)
let get_current_user () =
  match Eliom_reference.Volatile.get me with
  | CU_user a -> a
  | CU_idontknown -> failwith please_use_connected_fun
  | CU_notconnected -> raise Os_session.Not_connected

let get_current_user_option () =
  let u = Eliom_reference.Volatile.get me in
  match u with
  | CU_user a -> Some a
  | CU_idontknown -> failwith please_use_connected_fun
  | CU_notconnected -> None

let%shared get_current_userid () =
  Os_user.userid_of_user (get_current_user ())

[%%shared
  module Opt = struct

    let get_current_user = get_current_user_option

    let get_current_userid () =
      Eliom_lib.Option.map
        Os_user.userid_of_user
        (get_current_user_option ())

  end
]

let%client _ =
  Os_session.get_current_userid_o := Opt.get_current_userid

let%server set_user_server myid =
  let%lwt u = Os_user.user_of_userid myid in
  Eliom_reference.Volatile.set me (CU_user u);
  Lwt.return ()

let%server unset_user_server () =
  Eliom_reference.Volatile.set me CU_notconnected

let%server set_user_client () =
  let u = Eliom_reference.Volatile.get me in
  ignore [%client ( me := ~%u : unit)]

let%server unset_user_client () =
  ignore [%client ( me := CU_notconnected : unit)]

let%server () =
  Os_session.on_request (fun myid ->
    (* I initialize current user to CU_notconnected *)
    Lwt_log.ign_debug ~section "request action";
    unset_user_server ();
    Lwt.return ());
  Os_session.on_start_connected_process (fun myid ->
    Lwt_log.ign_debug ~section "start connected process action";
    let%lwt () = set_user_server myid in
    set_user_client ();
    Lwt.return ());
  Os_session.on_connected_request (fun myid ->
    Lwt_log.ign_debug ~section "connected request action";
    set_user_server myid);
  Os_session.on_pre_close_session (fun () ->
    Lwt_log.ign_debug ~section "pre close session action";
    unset_user_client (); (*VVV!!! will affect only current tab!! *)
    unset_user_server (); (* ok this is a request reference *)
    Lwt.return ());
  Os_session.on_start_process (fun () ->
    Lwt_log.ign_debug ~section "start process action";
    Lwt.return ());
  Os_session.on_open_session (fun _ ->
    Lwt_log.ign_debug ~section "open session action";
    Lwt.return ());
  Os_session.on_denied_request (fun _ ->
    Lwt_log.ign_debug ~section "denied request action";
    Lwt.return ())

let%server remove_email_from_user email =
  let myid = get_current_userid () in
  Os_user.remove_email_from_user ~userid:myid ~email

let%client remove_email_from_user email =
  ~%(Eliom_client.server_function
      [%derive.json: string]
      (Os_session.connected_wrapper remove_email_from_user)
  )
  email

let%server update_main_email email =
  let myid = get_current_userid () in
  Os_user.update_main_email ~userid:myid ~email

let%client update_main_email email =
  ~%(Eliom_client.server_function
      [%derive.json: string]
      (Os_session.connected_wrapper update_main_email)
  )
  email

let%server is_email_validated email =
  let myid = get_current_userid () in
  Os_user.is_email_validated ~userid:myid ~email

let%client is_email_validated email =
  ~%(Eliom_client.server_function
      [%derive.json: string]
      (Os_session.connected_wrapper is_email_validated)
  )
  email

let%server is_main_email email =
  let myid = get_current_userid () in
  Os_user.is_main_email ~userid:myid ~email

let%client is_main_email email =
  ~%(Eliom_client.server_function
     [%derive.json: string]
     (Os_session.connected_wrapper is_main_email)
  )
  email
