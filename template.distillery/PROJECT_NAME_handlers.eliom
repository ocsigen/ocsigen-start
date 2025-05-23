open%shared Lwt.Syntax

(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)

[%%shared open Eliom_content.Html.F]

(* Upload user avatar *)
let upload_user_avatar_handler myid () ((), (cropping, photo)) =
  let avatar_dir =
    List.fold_left Filename.concat
      (List.hd !%%%MODULE_NAME%%%_config.avatar_dir)
      (List.tl !%%%MODULE_NAME%%%_config.avatar_dir)
  in
  let* avatar = Os_uploader.record_image avatar_dir ~ratio:1. ?cropping photo in
  let* user = Os_user.user_of_userid myid in
  let old_avatar = Os_user.avatar_of_user user in
  let* () = Os_user.update_avatar ~userid:myid ~avatar in
  match old_avatar with
  | None -> Lwt.return_unit
  | Some old_avatar -> Lwt_unix.unlink (Filename.concat avatar_dir old_avatar)

(* Set personal data *)

let%server set_personal_data_handler =
  Os_session.connected_fun Os_handlers.set_personal_data_handler

let%rpc set_personal_data_rpc (data : (string * string) * (string * string)) :
    unit Lwt.t
  =
  set_personal_data_handler () data

let%client set_personal_data_handler () = set_personal_data_rpc

(* Forgot password *)

let%server forgot_password_handler =
  Os_handlers.forgot_password_handler %%%MODULE_NAME%%%_services.settings_service

let%rpc forgot_password_rpc (email : string) : unit Lwt.t =
  forgot_password_handler () email

let%client forgot_password_handler () = forgot_password_rpc

(* Action links are links created to perform an action. They are used
   for example to send activation links by email, or links to reset a
   password. You can create your own action links and define their
   behavior here. *)
let%shared action_link_handler myid_o akey () =
  Lwt.catch
    (fun () ->
       (* We try first the default actions (activation link, reset
     password) *)
       Os_handlers.action_link_handler myid_o akey ())
    (function
       | Os_handlers.No_such_resource | Os_handlers.Invalid_action_key _ ->
           Os_msg.msg ~level:`Err ~onload:true [%i18n S.invalid_action_key];
           Eliom_registration.(appl_self_redirect Action.send) ()
       | e ->
           let* email, phantom_user =
             match e with
             | Os_handlers.Account_already_activated_unconnected
                 { Os_types.Action_link_key.userid = _
                 ; email
                 ; validity = _
                 ; action = _
                 ; data = _
                 ; autoconnect = _ } ->
                 Lwt.return (email, false)
             | Os_handlers.Custom_action_link
                 ( { Os_types.Action_link_key.userid = _
                   ; email
                   ; validity = _
                   ; action = _
                   ; data = _
                   ; autoconnect = _ }
                 , phantom_user ) ->
                 Lwt.return (email, phantom_user)
             | _ -> Lwt.fail e
           in
           (* Define here your custom action links. If phantom_user is true,
       it means the link has been created for an email that does not
       correspond to an existing user. By default, we just display a
       sign up form or phantom users, a login form for others.  You
       don't need to modify this if you are not using custom action
       links.

       Perhaps personalise the intended behavior for when you meet
       [Account_already_activated_unconnected].  *)
           if myid_o = None (* Not currently connected, and no autoconnect *)
           then
             if phantom_user
             then
               let page =
                 [ div
                     ~a:[a_class ["login-signup-box"]]
                     [ Os_user_view.sign_up_form
                         ~a_placeholder_email:[%i18n S.your_email]
                         ~text:[%i18n S.sign_up] ~email () ] ]
               in
               %%%MODULE_NAME%%%_base.App.send
                 (%%%MODULE_NAME%%%_page.make_page (Os_page.content page))
             else
               let page =
                 [ div
                     ~a:[a_class ["login-signup-box"]]
                     [ Os_user_view.connect_form
                         ~a_placeholder_email:[%i18n S.your_email]
                         ~a_placeholder_pwd:[%i18n S.your_password]
                         ~text_keep_me_logged_in:[%i18n S.keep_logged_in]
                         ~text_sign_in:[%i18n S.sign_in] ~email () ] ]
               in
               %%%MODULE_NAME%%%_base.App.send
                 (%%%MODULE_NAME%%%_page.make_page (Os_page.content page))
           else
             (*VVV In that case we must do something more complex. Check
               whether myid = userid and ask the user what he wants to
               do. *)
             let open Eliom_registration in
             appl_self_redirect Redirection.send
               (Redirection Eliom_service.reload_action))

(* Set password *)

let%server set_password_handler =
  Os_session.connected_fun (fun myid () (pwd, pwd2) ->
    let* () = Os_handlers.set_password_handler myid () (pwd, pwd2) in
    Lwt.return (Eliom_registration.Redirection Eliom_service.reload_action))

let%client set_password_handler () (pwd, pwd2) =
  let* () = Os_handlers.set_password_rpc (pwd, pwd2) in
  Lwt.return (Eliom_registration.Redirection Eliom_service.reload_action)

(* Preregister *)

let%server preregister_handler = Os_handlers.preregister_handler

let%rpc preregister_rpc (email : string) : unit Lwt.t =
  preregister_handler () email

let%client preregister_handler () = preregister_rpc

let%shared main_service_handler myid_o () () =
  %%%MODULE_NAME%%%_container.page
    ~a:[a_class ["os-page-main"]]
    myid_o
    [ p [%i18n welcome_text1]
    ; p [%i18n welcome_text2]
    ; ul [li [%i18n welcome_text3]; li [%i18n welcome_text4]]
    ; p [%i18n welcome_text5]
    ; ul
        [ li [%i18n welcome_text6]
        ; li [%i18n welcome_text7]
        ; li [%i18n welcome_text8]
        ; li [%i18n welcome_text9]
        ; li [%i18n welcome_text10] ]
    ; p [%i18n welcome_text11] ]

let%shared about_handler myid_o () () =
  let open Eliom_content.Html.F in
  %%%MODULE_NAME%%%_container.page
    ~a:[a_class ["os-page-about"]]
    myid_o
    [ div
        [ p [%i18n about_handler_template]
        ; br ()
        ; p [%i18n about_handler_license] ] ]

let%shared settings_handler myid_o () () =
  let* content =
    match myid_o with
    | Some _ -> %%%MODULE_NAME%%%_settings.settings_content ()
    | None -> Lwt.return [p [%i18n log_in_to_see_page ~capitalize:true]]
  in
  %%%MODULE_NAME%%%_container.page myid_o content

let%server update_language_handler () language =
  Os_session.connected_wrapper %%%MODULE_NAME%%%_language.update_language
    (%%%MODULE_NAME%%%_i18n.language_of_string language)

let%client update_language_handler () language =
  %%%MODULE_NAME%%%_i18n.(set_language (language_of_string language));
  Os_current_user.update_language language
