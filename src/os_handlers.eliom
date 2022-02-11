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

(** Registration of default services *)

open%shared Eliom_content.Html
open%shared Eliom_content.Html.F
open%client Js_of_ocaml

let%client storage () =
  Js.Optdef.case
    Dom_html.window##.localStorage
    (fun () -> failwith "Browser storage not supported")
    (fun v -> v)

(* Set personal data *)
let%server set_personal_data_handler myid ()
    (((firstname, lastname), (pwd, pwd2)) as pd)
  =
  if firstname = "" || lastname = "" || pwd <> pwd2
  then (
    Eliom_reference.Volatile.set Os_msg.wrong_pdata (Some pd);
    Lwt.return_unit)
  else
    let%lwt user = Os_user.user_of_userid myid in
    let open Os_types.User in
    let record = {user with fn = firstname; ln = lastname} in
    Os_user.update' ~password:pwd record

(* Set password handler *)
let%server set_password_handler myid () (pwd, pwd2) =
  if pwd <> pwd2
  then (
    Os_msg.msg ~level:`Err ~onload:true "Passwords do not match";
    Lwt.return_unit)
  else
    let%lwt user = Os_user.user_of_userid myid in
    Os_user.update' ~password:pwd user

(* Set password RPC *)
let%rpc set_password_rpc myid (p : string * string) : unit Lwt.t =
  set_password_handler myid () p

let%server generate_action_link_key
    ?(act_key = Ocsigen_lib.make_cryptographic_safe_string ())
    ?(send_email = true) ~service ~text email
  =
  let service =
    Eliom_service.attach ~fallback:service
      ~service:Os_services.action_link_service ()
  in
  let act_link = Eliom_uri.make_string_uri ~absolute:true ~service act_key in
  (* For debugging we print the action link on standard output
     to make possible to connect even if the mail transport is not
     configured. *)
  if Ocsigen_config.get_debugmode ()
  then print_endline ("Debug: action link created: " ^ act_link);
  if send_email
  then
    Lwt.async (fun () ->
        try%lwt
          Os_email.send ~to_addrs:["", email] ~subject:"creation" ~url:act_link
            [text]
        with _ -> Lwt.return_unit);
  act_key

(** For default value of [autoconnect], cf. [Os_user.add_actionlinkkey]. *)
let%server send_action_link ?autoconnect ?action ?validity ?expiry msg service
    email userid
  =
  let act_key = generate_action_link_key ~service ~text:msg email in
  Eliom_reference.Volatile.set Os_msg.action_link_key_created true;
  let%lwt () =
    Os_user.add_actionlinkkey ?autoconnect ?action ?validity ?expiry ~act_key
      ~userid ~email ()
  in
  Lwt.return_unit

(* Sign up *)
let%server sign_up_handler () email =
  let send_action_link email userid =
    let msg =
      "Welcome!\r\nTo confirm your e-mail address, please click on this link: "
    in
    send_action_link ~validity:1L
      ~expiry:CalendarLib.Calendar.(add (now ()) (Period.hour 1))
      ~autoconnect:true msg Os_services.main_service email userid
  in
  try%lwt
    let%lwt user = Os_user.create ~firstname:"" ~lastname:"" ~email () in
    let userid = Os_user.userid_of_user user in
    Os_msg.msg ~onload:true ~level:`Msg ~duration:6.
      "An e-mail was sent to this address. Click on the link it contains to activate your account.";
    send_action_link email userid
  with Os_user.Already_exists userid ->
    (* If email is not validated, the user never logged in,
       I send an action link, as if it were a new user. *)
    let%lwt validated = Os_db.User.is_email_validated userid email in
    if not validated
    then send_action_link email userid
    else (
      Eliom_reference.Volatile.set Os_user.user_already_exists true;
      Os_msg.msg ~level:`Err ~onload:true "E-mail already exists";
      Lwt.return_unit)

let%rpc sign_up_handler_rpc (email : string) : unit Lwt.t =
  sign_up_handler () email

let%client sign_up_handler () v = sign_up_handler_rpc v

(* Forgot password *)
let%server forgot_password_handler service () email =
  try%lwt
    let%lwt userid = Os_user.userid_of_email email in
    let msg = "Hi,\r\nTo set a new password, please click on this link: " in
    Os_msg.msg ~level:`Msg ~onload:true
      "An email was sent to this address. Click on the link it contains to reset your password.";
    send_action_link ~autoconnect:true ~action:`PasswordReset ~validity:1L
      ~expiry:CalendarLib.Calendar.(add (now ()) (Period.hour 1))
      msg service email userid
  with Os_db.No_such_resource ->
    Eliom_reference.Volatile.set Os_user.user_does_not_exist true;
    Os_msg.msg ~level:`Err ~onload:true "User does not exist";
    Lwt.return_unit

let%client restart ?url () =
  (* Restart the client.
     On a Web app, it is just reloading the page.
     On a mobile app, we want to restart from eliom.html.
  *)
  if Eliom_client.is_client_app ()
  then (
    (match url with
    | Some url ->
        (storage ())##setItem (Js.string "__os_restart_url") (Js.string url)
    | None -> ());
    Dom_html.window##.location##.href := Js.string "eliom.html")
  else
    match url with
    | Some url ->
        (* [Eliom_client.exit_to] ends up setting [.href], so we do the
         same. We do not have an "untyped" [exit_to], and
         reconstructing the params from the URL only to rebuild the
         URL would be crazy *)
        Dom_html.window##.location##.href := Js.string url
    | None ->
        (* By default, we restart at main page, to have the same behaviour
         as in the app. *)
        Eliom_client.exit_to ~service:Os_services.main_service () ()

(* Disconnection *)
(* By default, disconnect_handler stays on the same page.
   If [main_page] is true, it goes to the main page.
*)
let disconnect_handler ?(main_page = false) () () =
  (* SECURITY: no check here because we disconnect the session cookie owner. *)
  let%lwt () = Os_session.disconnect () in
  ignore
    [%client
      (restart
         ?url:
           (if ~%main_page
           then None
           else
             Some
               (make_uri ~absolute:true ~service:Eliom_service.reload_action ()))
         ()
        : unit)];
  Lwt.return_unit

let%rpc disconnect_handler_rpc (main_page : bool) =
  disconnect_handler ~main_page () ()

let%client disconnect_handler ?(main_page = false) () () =
  disconnect_handler_rpc main_page

(* Connection *)
let connect_handler () ((login, pwd), keepmeloggedin) =
  (* SECURITY: no check here. *)
  try%lwt
    let%lwt userid = Os_user.verify_password login pwd in
    let%lwt () = disconnect_handler () () in
    Os_session.connect ~expire:(not keepmeloggedin) userid
  with
  | Os_db.Account_not_activated ->
      Eliom_reference.Volatile.set Os_user.account_not_activated true;
      Os_msg.msg ~level:`Err ~onload:true "Account not activated";
      Lwt.return_unit
  | Os_db.Empty_password | Os_db.Password_not_set | Os_db.Wrong_password ->
      Eliom_reference.Volatile.set Os_user.wrong_password true;
      Os_msg.msg ~level:`Err ~onload:true "Wrong password";
      Lwt.return_unit
  | Os_db.No_such_user ->
      Eliom_reference.Volatile.set Os_user.no_such_user true;
      Os_msg.msg ~level:`Err ~onload:true "No such user";
      Lwt.return_unit

let%rpc connect_handler_rpc (v : (string * string) * bool) : unit Lwt.t =
  connect_handler () v

let%client connect_handler () v = connect_handler_rpc v

[%%shared
exception Custom_action_link of Os_types.Action_link_key.info * bool
(* If true, the link corresponds to a phantom user
                (user who never created its account).
                In that case, you probably want to display a sign-up form,
                and in the other case a login form. *)

exception Account_already_activated_unconnected of Os_types.Action_link_key.info

exception
  Account_already_activated_connected of
    Os_types.Action_link_key.info * Os_types.User.id

exception Invalid_action_key of Os_types.Action_link_key.info
exception No_such_resource]

let%rpc action_link_handler_common myid_o (akey : string)
    : [ `Account_already_activated_unconnected of Os_types.Action_link_key.info
      | `Custom_action_link of Os_types.Action_link_key.info * bool
      | `Invalid_action_key of Os_types.Action_link_key.info
      | `No_such_resource
      | `Reload
      | `Restart_if_app ]
    Lwt.t
  =
  try%lwt
    let open Os_types.Action_link_key in
    let%lwt ({userid; email; validity; expiry; action; data = _; autoconnect} as
            action_link)
      =
      Os_user.get_actionlinkkey_info akey
    in
    let%lwt () =
      if action = `AccountActivation && validity <= 0L
      then
        match myid_o with
        | Some myid ->
            Lwt.fail (Account_already_activated_connected (action_link, myid))
        | None -> Lwt.fail (Account_already_activated_unconnected action_link)
      else Lwt.return_unit
    in
    let outdated =
      match expiry with
      | None -> false
      | Some e -> e <= CalendarLib.Calendar.now ()
    in
    let%lwt () =
      if validity <= 0L || outdated
      then Lwt.fail (Invalid_action_key action_link)
      else Lwt.return_unit
    in
    let%lwt () =
      if action = `AccountActivation || action = `PasswordReset
      then Os_db.User.set_email_validated userid email
      else Lwt.return_unit
    in
    if autoconnect && myid_o <> Some userid
    then
      let%lwt () = Os_session.connect userid in
      Lwt.return `Restart_if_app
    else
      match action with
      | `Custom s ->
          let%lwt existing_user = Os_db.User.is_email_validated userid email in
          Lwt.return (`Custom_action_link (action_link, not existing_user))
      | _ -> Lwt.return `Reload
  with
  | Os_db.No_such_resource -> Lwt.return `No_such_resource
  | Invalid_action_key action_link ->
      Eliom_reference.Volatile.set Os_user.action_link_key_outdated true;
      Lwt.return (`Invalid_action_key action_link)
  | Account_already_activated_unconnected action_link ->
      Eliom_reference.Volatile.set Os_user.action_link_key_outdated true;
      Lwt.return (`Account_already_activated_unconnected action_link)
  | Account_already_activated_connected (action_link, _) ->
      Eliom_reference.Volatile.set Os_user.action_link_key_outdated true;
      (* Just reload the page without the GET parameters to get rid of the key.
       If the user wasn't already logged in, let the exception pass to the
       next exception handler. *)
      Lwt.return `Reload

let%client restart_if_client_side () =
  restart
    ~url:(make_uri ~absolute:true ~service:Eliom_service.reload_action ())
    ()

let%server restart_if_client_side () = ()

let%shared action_link_handler _myid_o akey () =
  let%lwt a = action_link_handler_common akey in
  match a with
  | `Reload ->
      Eliom_registration.(
        appl_self_redirect Redirection.send
          (Redirection Eliom_service.reload_action))
  | `No_such_resource -> Lwt.fail No_such_resource
  | `Invalid_action_key action_link -> Lwt.fail (Invalid_action_key action_link)
  | `Restart_if_app ->
      restart_if_client_side ();
      Eliom_registration.(appl_self_redirect Action.send) ()
  | `Custom_action_link (action_link, phantom_user) ->
      Lwt.fail (Custom_action_link (action_link, phantom_user))
  | `Account_already_activated_unconnected action_link ->
      Lwt.fail (Account_already_activated_unconnected action_link)

(* Preregister *)
let preregister_handler () email =
  let%lwt is_preregistered = Os_user.is_preregistered email in
  let%lwt is_registered = Os_user.is_registered email in
  Printf.printf "%b:%b%!\n" is_preregistered is_registered;
  if not (is_preregistered || is_registered)
  then Os_user.add_preregister email
  else (
    Eliom_reference.Volatile.set Os_user.user_already_preregistered true;
    Os_msg.msg ~level:`Err ~onload:true "E-mail already preregistered";
    Lwt.return_unit)

(* Add email *)
let add_email_handler =
  let msg =
    "Welcome!\r\nTo confirm your e-mail address, please click on this link: "
  in
  let send_act () =
    send_action_link ~autoconnect:true msg
      (match Os_services.settings_service () with
      | Some service -> service
      | None -> Os_services.main_service)
  in
  let add_email myid () email =
    let%lwt available = Os_db.Email.available email in
    if available
    then
      let%lwt () = Os_db.User.add_email_to_user ~userid:myid ~email in
      send_act () email myid
    else (
      Eliom_reference.Volatile.set Os_user.user_already_exists true;
      Lwt.return_unit)
  in
  Os_session.connected_fun add_email

let%rpc add_email_rpc (email : string) : unit Lwt.t = add_email_handler () email
let%client add_email_handler () = add_email_rpc
let%shared _ = Os_comet.__link (* to make sure os_comet is linked *)

let%client input_popup ?(button_label = "OK") f =
  let w, u = Lwt.wait () in
  let content close =
    let open Eliom_content.Html in
    let button = D.button ~a:[D.a_class ["button"]] [D.txt button_label] in
    let inp =
      let f code =
        let%lwt () = close () in
        Lwt.wakeup u (); f code
      in
      Os_lib.lwt_bound_input_enter ~button f
    in
    Lwt.return (D.div [button; inp])
  in
  let%lwt _ = Ot_popup.popup ~close_button:[Os_icons.F.close ()] content in
  w

let%client confirm_code_popup ~dest f =
  input_popup @@ fun code ->
  let%lwt b = f code in
  if b
  then
    let service =
      match dest with
      | `Settings -> Os_services.settings_service ()
      | `Main -> Some Os_services.main_service
    in
    match service with
    | Some service -> Eliom_client.change_page ~service () ()
    | None -> Lwt.fail_with "confirm_popup: settings service unknown"
  else (
    Os_msg.msg ~level:`Err ~duration:2. "Wrong SMS activation code";
    Lwt.return_unit)

(* We only need confirm_code_*_service to implement the activation
   UI. Assuming normal user behavior, we will only ever call them via
   a client-side Eliom_client.change_page, so no server implementation
   is needed. Currently we can't register a service only on the
   client.  Until we fix Eliom, we define dummy server-side
   handlers. *)
let%server confirm_code_handler _ _ =
  Lwt.fail_with
    "Os_handlers.confirm_code_*_handler not implemented on the server"

let%server confirm_code_signup_handler = confirm_code_handler
let%server confirm_code_extra_handler = confirm_code_handler
let%server confirm_code_recovery_handler = confirm_code_handler

let%client request_activation_code_wrapper number f =
  match%lwt Os_connect_phone.request_code number with
  | Ok () -> f ()
  | Error `Ownership ->
      Os_msg.msg ~level:`Err ~duration:2. "Phone taken";
      Lwt.return_unit
  | Error (`Unknown | `Send | `Limit | `Invalid_number) ->
      Os_msg.msg ~level:`Err ~duration:2. "SMS error";
      Lwt.return_unit

let%client confirm_code_signup_handler ()
    (first_name, (last_name, (password, number)))
  =
  request_activation_code_wrapper number @@ fun () ->
  confirm_code_popup ~dest:`Main @@ fun code ->
  Os_connect_phone.confirm_code_signup ~first_name ~last_name ~code ~password ()

let%client confirm_code_extra_handler () number =
  request_activation_code_wrapper number @@ fun () ->
  confirm_code_popup ~dest:`Settings Os_connect_phone.confirm_code_extra

let%client confirm_code_recovery_handler () number =
  match%lwt Os_connect_phone.request_recovery_code number with
  | Ok () ->
      confirm_code_popup ~dest:`Settings Os_connect_phone.confirm_code_recovery
  | Error (`Unknown | `Send | `Limit | _) ->
      Os_msg.msg ~level:`Err ~duration:2. "SMS error";
      Lwt.return ()
