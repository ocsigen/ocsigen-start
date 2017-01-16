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

[%%shared
  open Eliom_content.Html
  open Eliom_content.Html.F
]

let%client storage () =
  Js.Optdef.case (Dom_html.window##.localStorage)
    (fun () -> failwith "Browser storage not supported")
    (fun v -> v)

(* Set personal data *)
let%server set_personal_data_handler myid ()
    (((firstname, lastname), (pwd, pwd2)) as pd) =
  if firstname = "" || lastname = "" || pwd <> pwd2
  then
    (Eliom_reference.Volatile.set Os_msg.wrong_pdata (Some pd);
     Lwt.return ())
  else (
    let%lwt user = Os_user.user_of_userid myid in
    let open Os_types.User in
    let record = {
      user with
      fn = firstname;
      ln = lastname;
    } in
    Os_user.update' ~password:pwd record)

(* Set password handler *)
let%server set_password_handler myid () (pwd, pwd2) =
  if pwd <> pwd2
  then
    (Os_msg.msg ~level:`Err ~onload:true "Passwords do not match";
     Lwt.return ())
  else (
    let%lwt user = Os_user.user_of_userid myid in
    Os_user.update' ~password:pwd user)

(* Set password RPC *)
let%client set_password_rpc =
  ~%(Eliom_client.server_function
       ~name:"Os_handlers.set_password_rpc"
       [%derive.json: string * string]
       (Os_session.connected_rpc
          (fun myid p -> set_password_handler myid () p))
    )

let%server generate_action_link_key
    ?(act_key = Ocsigen_lib.make_cryptographic_safe_string ())
    ?(send_email = true)
    ~service
    ~text
    email =
  let service =
    Eliom_service.attach
      ~fallback:service
      ~service:Os_services.action_link_service
      ()
  in
  let act_link = Eliom_uri.make_string_uri ~absolute:true ~service act_key in
  (* For debugging we print the action link on standard output
     to make possible to connect even if the mail transport is not
     configured. *)
  if Ocsigen_config.get_debugmode ()
  then print_endline ("Debug: action link created: "^act_link);
  if send_email
  then
    Lwt.async (fun () ->
      try%lwt
        Os_email.send
          ~to_addrs:[("", email)]
          ~subject:"creation"
          [
            text;
            act_link;
          ]
      with _ -> Lwt.return ());
  act_key


(** For default value of [autoconnect], cf. [Os_user.add_actionlinkkey]. *)
let%server send_action_link
    ?autoconnect
    ?action
    ?validity
    msg
    service
    email
    userid
  =
  let act_key =
    generate_action_link_key
      ~service:service
      ~text:msg
      email
  in
  Eliom_reference.Volatile.set Os_msg.action_link_key_created true;
  let%lwt () =
    Os_user.add_actionlinkkey
      ?autoconnect ?action ?validity ~act_key ~userid ~email ()
  in
  Lwt.return ()

(* Sign up *)
let%server sign_up_handler () email =
  let send_action_link email userid =
    let msg =
      "Welcome!\r\nTo confirm your e-mail address, \
       please click on this link: " in
    send_action_link ~autoconnect:true msg Os_services.main_service email userid
  in
  try%lwt
    let%lwt user = Os_user.create ~firstname:"" ~lastname:"" email in
    let userid = Os_user.userid_of_user user in
    Os_msg.msg ~onload:true ~level:`Msg ~duration:6.
      "An e-mail was sent to this address. \
       Click on the link it contains to activate your account.";
    send_action_link email userid
  with Os_user.Already_exists userid ->
    (* If email is not validated, the user never logged in,
       I send an action link, as if it were a new user. *)
    let%lwt validated = Os_db.User.is_email_validated userid email in
    if not validated
    then send_action_link email userid
    else begin
      Eliom_reference.Volatile.set Os_user.user_already_exists true;
      Os_msg.msg ~level:`Err ~onload:true "E-mail already exists";
      Lwt.return ()
    end

let%server sign_up_handler_rpc v =
  (Os_session.connected_wrapper (sign_up_handler ())) v

let%client sign_up_handler_rpc =
  ~%(Eliom_client.server_function
       ~name:"Os_handlers.sign_up_handler"
       [%derive.json: string]
       sign_up_handler_rpc)

let%client sign_up_handler () v =
  sign_up_handler_rpc v

(* Forgot password *)
let%server forgot_password_handler service () email =
  try%lwt
    let%lwt userid = Os_user.userid_of_email email in
    let msg = "Hi,\r\nTo set a new password, \
               please click on this link: " in
    Os_msg.msg ~level:`Msg ~onload:true "An email was sent to this address. Click on the link it contains to reset your password.";
    send_action_link ~autoconnect:true ~action:`PasswordReset ~validity:1L
      msg service email userid
  with Os_db.No_such_resource ->
    Eliom_reference.Volatile.set Os_user.user_does_not_exist true;
    Os_msg.msg ~level:`Err ~onload:true "User does not exist";
    Lwt.return ()

let%client restart ?url () =
  (* Restart the client.
     On a Web app, it is just reloading the page.
     On a mobile app, we want to restart from eliom.html.
  *)
  if Eliom_client.is_client_app () then
    ((match url with
       | Some url ->
         (storage ())##setItem
           (Js.string "__os_restart_url")
           (Js.string url)
       | None ->
         ());
     Eliom_client.exit_to ~absolute:false
       ~service:(Eliom_service.static_dir ())
       ["eliom.html"] ())
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
      Eliom_client.exit_to
        ~service:Os_services.main_service
        () ()

(* Disconnection *)
(* By default, disconnect_handler stays on the same page.
   If [main_page] is true, it goes to the main page.
*)
let disconnect_handler ?(main_page = false) () () =
  (* SECURITY: no check here because we disconnect the session cookie owner. *)
  let%lwt () = Os_session.disconnect () in
  ignore [%client (restart
                     ?url:(if ~%main_page
                           then None
                           else
                             Some (make_uri
                                     ~absolute:true
                                     ~service:Eliom_service.reload_action ()))
                     ()
                   : unit)];
  Lwt.return ()

let%server disconnect_handler_rpc main_page =
  disconnect_handler ~main_page () ()

let%client disconnect_handler_rpc  =
  ~%(Eliom_client.server_function
       ~name:"Os_handlers.disconnect_handler"
       [%derive.json: bool]
       disconnect_handler_rpc)

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
      Lwt.return ()
  | Os_db.No_such_resource ->
      Eliom_reference.Volatile.set Os_user.wrong_password true;
      Os_msg.msg ~level:`Err ~onload:true "Wrong password";
      Lwt.return ()

let%server connect_handler_rpc v = connect_handler () v

let%client connect_handler_rpc =
  ~%(Eliom_client.server_function
       ~name:"Os_handlers.connect_handler"
       [%derive.json: (string * string) * bool]
       connect_handler_rpc)

let%client connect_handler () v = connect_handler_rpc v

[%%shared
  exception Custom_action_link of
      Os_types.Action_link_key.info
      * bool (* If true, the link corresponds to a phantom user
                (user who never created its account).
                In that case, you probably want to display a sign-up form,
                and in the other case a login form. *)

  exception Account_already_activated_unconnected of Os_types.Action_link_key.info
  exception Account_already_activated_connected of
      Os_types.Action_link_key.info * Os_types.User.id
  exception Invalid_action_key of Os_types.Action_link_key.info
  exception No_such_resource
]

let action_link_handler_common akey =
  let myid_o = Os_current_user.Opt.get_current_userid () in
  try%lwt
    let open Os_types.Action_link_key in
    let%lwt
      {userid; email; validity; action; data = _; autoconnect}
      as action_link =
      Os_user.get_actionlinkkey_info akey
    in
    let%lwt () =
      if action = `AccountActivation && validity <= 0L
      then
        match myid_o with
        | Some myid ->
           Lwt.fail (Account_already_activated_connected (action_link, myid))
        | None ->
           Lwt.fail (Account_already_activated_unconnected action_link)
      else Lwt.return_unit
    in
    let%lwt () =
      if validity <= 0L
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
      let%lwt () = Os_session.disconnect () in
      let%lwt () = Os_session.connect userid in
      Lwt.return `Restart_if_app
    else
      match action with
      | `Custom s ->
        let%lwt existing_user = Os_db.User.is_email_validated userid email in
        Lwt.return (`Custom_action_link (action_link, not existing_user))
      | _ -> Lwt.return `Reload

  with
  | Os_db.No_such_resource ->
    Lwt.return `No_such_resource
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

let%client action_link_handler_common =
  ~%(Eliom_client.server_function ~name:"Os_handlers.action_link_handler_common"
       [%derive.json: string]
       (Os_session.connected_wrapper action_link_handler_common))

let%client restart_if_client_side () =
  restart ~url:(make_uri
                  ~absolute:true
                  ~service:Eliom_service.reload_action ()) ()
let%server restart_if_client_side () = ()

let%shared action_link_handler _myid_o akey () =
  let%lwt a = action_link_handler_common akey in
  match a with
  | `Reload ->
    Eliom_registration.
      (appl_self_redirect
         Redirection.send
         (Redirection Eliom_service.reload_action))
  | `No_such_resource ->
    Lwt.fail No_such_resource
  | `Invalid_action_key action_link ->
    Lwt.fail (Invalid_action_key action_link)
  | `Restart_if_app ->
    restart_if_client_side ();
    Eliom_registration.(appl_self_redirect Action.send) ()
  | `Custom_action_link (action_link, phantom_user) ->
    Lwt.fail (Custom_action_link (action_link, phantom_user))
  | `Account_already_activated_unconnected (action_link) ->
    Lwt.fail (Account_already_activated_unconnected (action_link))


(* Preregister *)
let preregister_handler () email =
  let%lwt is_preregistered = Os_user.is_preregistered email in
  let%lwt is_registered = Os_user.is_registered email in
  Printf.printf "%b:%b%!\n" is_preregistered is_registered;
  if not (is_preregistered || is_registered)
   then Os_user.add_preregister email
   else begin
     Eliom_reference.Volatile.set Os_user.user_already_preregistered true;
     Os_msg.msg ~level:`Err ~onload:true "E-mail already preregistered";
     Lwt.return ()
   end

(* Add email *)
let%server add_email_handler =
  let msg =
    "Welcome!\r\nTo confirm your e-mail address, \
       please click on this link: "
  in
  let send_act =
    send_action_link  ~autoconnect:true msg Os_services.main_service
  in
  let add_email myid () email =
    let%lwt available = Os_db.Email.available email in
    if available then
      let%lwt () = Os_db.User.add_email_to_user ~userid:myid ~email in
      send_act email myid
    else begin
      Eliom_reference.Volatile.set Os_user.user_already_exists true;
      Os_msg.msg ~level:`Err ~onload:true "E-mail already exists";
      Lwt.return_unit
    end
  in
  Os_session.connected_fun add_email

let%client add_email_handler =
  let rpc = ~%(Eliom_client.server_function [%derive.json: string]
                 @@ add_email_handler ())
  in
  fun () -> rpc

let%shared _ = Os_comet.__link (* to make sure os_comet is linked *)
