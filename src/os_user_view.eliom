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

open%client Lwt.Syntax
open%shared Eliom_content.Html
open%shared Eliom_content.Html.F
open%client Js_of_ocaml
open%client Js_of_ocaml_lwt

let%shared enable_phone = ref false

let%client check_password_confirmation ~password ~confirmation =
  let password_dom = To_dom.of_input password in
  let confirmation_dom = To_dom.of_input confirmation in
  Lwt_js_events.async (fun () ->
    Lwt_js_events.inputs confirmation_dom (fun _ _ ->
      ignore
        (if Js.to_string password_dom##.value
            <> Js.to_string confirmation_dom##.value
         then
           (Js.Unsafe.coerce confirmation_dom)
           ## (setCustomValidity "Passwords do not match")
         else (Js.Unsafe.coerce confirmation_dom) ## (setCustomValidity ""));
      Lwt.return_unit))

let%shared generic_email_form ?a ?label
    ?(a_placeholder_email = "e-mail address") ?(text = "Send") ?(email = "")
    ~service ()
  =
  D.Form.post_form ?a ~service
    (fun name ->
       let l =
         [ D.Form.input
             ~a:[a_placeholder a_placeholder_email]
             ~input_type:`Email ~value:email ~name D.Form.string
         ; D.Form.input
             ~a:[a_class ["button"]]
             ~input_type:`Submit ~value:text D.Form.string ]
       in
       match label with None -> l | Some lab -> F.label [txt lab] :: l)
    ()

let%client form_override_phone phone_input form =
  let phone_input = To_dom.of_input phone_input
  and form = To_dom.of_form form in
  Lwt.async @@ fun () ->
  Lwt_js_events.submits form @@ fun ev _ ->
  let number = Js.to_string phone_input##.value in
  if number <> ""
  then
    Lwt.bind
      (let password = (Js.Unsafe.coerce form)##.password##.value |> Js.to_string
       and keepmeloggedin =
         (Js.Unsafe.coerce form)##.keepmeloggedin##.checked |> Js.to_bool
       in
       Dom.preventDefault ev;
       Os_connect_phone.connect ~keepmeloggedin ~password number)
      (function
         | `Login_ok -> Os_lib.reload ()
         | `Wrong_password ->
             Os_msg.msg ~level:`Err "Wrong password";
             Lwt.return_unit
         | `No_such_user ->
             Os_msg.msg ~level:`Err "No such user";
             Lwt.return_unit
         | `Password_not_set ->
             Os_msg.msg ~level:`Err "User password not set";
             Lwt.return_unit)
  else Lwt.return_unit

let%shared connect_form ?(a_placeholder_email = "Your email")
    ?(a_placeholder_phone = "Or your phone")
    ?(a_placeholder_pwd = "Your password")
    ?(text_keep_me_logged_in = "keep me logged in") ?(text_sign_in = "Sign in")
    ?a ?(email = "") ()
  =
  let phone_input =
    if !enable_phone
    then
      Some
        (D.input () ~a:[a_placeholder a_placeholder_phone; a_input_type `Tel])
    else None
  in
  let form =
    D.Form.post_form ?a ~service:Os_services.connect_service
      (fun ((login, password), keepmeloggedin) ->
         let l =
           [ D.Form.input
               ~a:[a_placeholder a_placeholder_pwd]
               ~name:password ~input_type:`Password D.Form.string
           ; label
               [ D.Form.bool_checkbox_one
                   ~a:[a_checked ()]
                   ~name:keepmeloggedin ()
               ; txt text_keep_me_logged_in ]
           ; D.Form.input
               ~a:[a_class ["button"; "os-sign-in"]]
               ~input_type:`Submit ~value:text_sign_in D.Form.string ]
         and mail_input =
           D.Form.input
             ~a:[a_placeholder a_placeholder_email]
             ~name:login ~input_type:`Email ~value:email D.Form.string
         in
         match phone_input with
         | Some phone_input -> mail_input :: phone_input :: l
         | None -> mail_input :: l)
      ()
  in
  (match phone_input with
  | Some phone_input ->
      ignore @@ [%client (form_override_phone ~%phone_input ~%form : unit)]
  | None -> ());
  form

let%shared disconnect_button ?a ?(text_logout = "Logout") () =
  D.Form.post_form ?a ~service:Os_services.disconnect_service
    (fun _ ->
       [ D.Form.button_no_value
           ~a:[a_class ["button"]]
           ~button_type:`Submit
           [Os_icons.F.signout (); txt text_logout] ])
    ()

let%shared sign_up_form ?a ?a_placeholder_email ?text ?email () =
  generic_email_form ?a ?a_placeholder_email ?text ?email
    ~service:Os_services.sign_up_service ()

let%shared forgot_password_form ?a () =
  generic_email_form ?a ~service:Os_services.forgot_password_service ()

let%client phone_input ~placeholder ~label f =
  let button = D.button ~a:[a_class ["button"]] [txt label] in
  let inp =
    Os_lib.lwt_bound_input_enter
      ~a:[D.a_placeholder placeholder; D.a_input_type `Tel]
      ~button f
  in
  D.div ~a:[D.a_class ["form-like"]] [inp; button]

let%client sign_up_by_phone_input ~placeholder label =
  phone_input ~placeholder ~label @@ fun number ->
  Eliom_client.change_page ~service:Os_services.confirm_code_signup_service ()
    ("", ("", ("", number)))

let%client forgot_password_phone_input ~placeholder label =
  phone_input ~placeholder ~label
    (Eliom_client.change_page ~service:Os_services.confirm_code_remind_service
       ())

let%shared information_form ?a ?(a_placeholder_password = "Your password")
    ?(a_placeholder_retype_password = "Retype password")
    ?(a_placeholder_firstname = "Your first name")
    ?(a_placeholder_lastname = "Your last name") ?(text_submit = "Submit")
    ?(firstname = "") ?(lastname = "") ?(password1 = "") ?(password2 = "") ()
  =
  D.Form.post_form ?a ~service:Os_services.set_personal_data_service
    (fun ((fname, lname), (passwordn1, passwordn2)) ->
       let pass1 =
         D.Form.input
           ~a:[a_placeholder a_placeholder_password]
           ~name:passwordn1 ~value:password1 ~input_type:`Password D.Form.string
       in
       let pass2 =
         D.Form.input
           ~a:[a_placeholder a_placeholder_retype_password]
           ~name:passwordn2 ~value:password2 ~input_type:`Password D.Form.string
       in
       let _ =
         [%client
           (check_password_confirmation ~password:~%pass1 ~confirmation:~%pass2
            : unit)]
       in
       [ D.Form.input
           ~a:[a_placeholder a_placeholder_firstname]
           ~name:fname ~value:firstname ~input_type:`Text D.Form.string
       ; D.Form.input
           ~a:[a_placeholder a_placeholder_lastname]
           ~name:lname ~value:lastname ~input_type:`Text D.Form.string
       ; pass1
       ; pass2
       ; D.Form.input
           ~a:[a_class ["button"]]
           ~input_type:`Submit ~value:text_submit D.Form.string ])
    ()

let%shared preregister_form ?a label =
  generic_email_form ?a ~service:Os_services.preregister_service ~label ()

let%shared home_button ?a () =
  D.Form.get_form ?a ~service:Os_services.main_service (fun _ ->
    [D.Form.input ~input_type:`Submit ~value:"home" D.Form.string])

let%shared avatar user =
  match Os_user.avatar_uri_of_user user with
  | Some src -> img ~alt:"picture" ~a:[a_class ["os-avatar"]] ~src ()
  | None -> Os_icons.F.user ()

let%shared username user =
  let n =
    match Os_user.firstname_of_user user with
    | "" ->
        let userid = Os_user.userid_of_user user in
        [txt ("User " ^ Int64.to_string userid)]
    | s -> [txt s; txt " "; txt (Os_user.lastname_of_user user)]
  in
  div ~a:[a_class ["os_username"]] n

let%shared password_form ?(a_placeholder_pwd = "password")
    ?(a_placeholder_confirmation = "retype your password")
    ?(text_send_button = "Send") ?a ~service ()
  =
  D.Form.post_form ?a ~service
    (fun (pwdn, pwd2n) ->
       let pass1 =
         D.Form.input
           ~a:
             [ a_required ()
             ; a_autocomplete `Off
             ; a_placeholder a_placeholder_pwd ]
           ~input_type:`Password ~name:pwdn D.Form.string
       in
       let pass2 =
         D.Form.input
           ~a:
             [ a_required ()
             ; a_autocomplete `Off
             ; a_placeholder a_placeholder_confirmation ]
           ~input_type:`Password ~name:pwd2n D.Form.string
       in
       ignore
         [%client
           (check_password_confirmation ~password:~%pass1 ~confirmation:~%pass2
            : unit)];
       [ pass1
       ; pass2
       ; D.Form.input ~input_type:`Submit
           ~a:[a_class ["button"]]
           ~value:text_send_button D.Form.string ])
    ()

let%shared upload_pic_link ?(a = []) ?(content = [txt "Change profile picture"])
    ?(crop = Some 1.)
    ?(input :
        Html_types.label_attrib Eliom_content.Html.D.Raw.attrib list
        * Html_types.label_content_fun Eliom_content.Html.D.Raw.elt list =
      [], [])
    ?(submit :
        Html_types.button_attrib Eliom_content.Html.D.Raw.attrib list
        * Html_types.button_content_fun Eliom_content.Html.D.Raw.elt list =
      [], [txt "Submit"])
    ?(onclick : (unit -> unit) Eliom_client_value.t =
      [%client (fun () -> () : unit -> unit)])
    (service : (unit, unit) Ot_picture_uploader.service)
  =
  D.Raw.a
    ~a:
      (a_onclick
         [%client
           (fun _ ->
              Lwt.async (fun () ->
                ~%onclick ();
                let upload_service ?progress ?cropping file =
                  Ot_picture_uploader.ocaml_service_upload ?progress ?cropping
                    ~service:~%service ~arg:() file
                in
                Lwt.catch
                  (fun () ->
                     ignore
                     @@ Ot_popup.popup
                          ~close_button:[Os_icons.F.close ()]
                          ~onclose:(fun () ->
                            Eliom_client.change_page
                              ~service:Eliom_service.reload_action () ())
                          (fun close ->
                             Ot_picture_uploader.mk_form ~crop:~%crop
                               ~input:~%input ~submit:~%submit
                               ~after_submit:close upload_service);
                     Lwt.return_unit)
                  (fun e ->
                     Os_msg.msg ~level:`Err "Error while uploading the picture";
                     Eliom_lib.debug_exn "%s" e "→ ";
                     Lwt.return_unit))
            : _)]
      :: a)
    content

let%shared reset_tips_link ?(text_link = "See help again from beginning")
    ?(close : (unit -> unit) Eliom_client_value.t =
      [%client (fun () -> () : unit -> unit)]) ()
  =
  let l = D.Raw.a [txt text_link] in
  ignore
    [%client
      (Lwt_js_events.(
         async (fun () ->
           clicks (To_dom.of_element ~%l) (fun _ _ ->
             ~%close ();
             Eliom_client.exit_to ~service:Os_tips.reset_tips_service () ();
             Lwt.return_unit)))
       : unit)];
  l

let%shared disconnect_all_link ?(text_link = "Logout on all my devices") () =
  let l = D.Raw.a [txt text_link] in
  ignore
    [%client
      (Lwt_js_events.(
         async (fun () ->
           clicks (To_dom.of_element ~%l) (fun _ _ ->
             Os_session.disconnect_all ())))
       : unit)];
  l

let%shared bind_popup_button ?a ~button
    ~(popup_content :
       ((unit -> unit Lwt.t)
        -> [< Html_types.div_content] Eliom_content.Html.elt Lwt.t)
         Eliom_client_value.t) ()
  =
  ignore
    [%client
      (Lwt.async (fun () ->
         Lwt_js_events.clicks (Eliom_content.Html.To_dom.of_element ~%button)
           (fun _ _ ->
              let* _ =
                Ot_popup.popup ?a:~%a
                  ~close_button:[Os_icons.F.close ()]
                  ~%popup_content
              in
              Lwt.return_unit))
       : _)]

let%client forgotpwd_button ?(content_popup = "Recover password")
    ?(text_button = "Forgot your password?")
    ?(phone_placeholder = "Or your phone") ?(text_send_button = "Send")
    ?(close = (fun () -> () : unit -> unit)) ()
  =
  let popup_content _ =
    let h = h2 [txt content_popup] in
    Lwt.return @@ div
    @@
    if !enable_phone
    then
      [ h
      ; forgot_password_form ()
      ; forgot_password_phone_input ~placeholder:phone_placeholder
          text_send_button ]
    else [h; forgot_password_form ()]
  in
  let button_name = text_button in
  let button =
    D.Raw.a
      ~a:[a_class ["os-forgot-pwd-link"]; a_onclick (fun _ -> close ())]
      [txt button_name]
  in
  bind_popup_button ~a:[a_class ["os-forgot-pwd"]] ~button ~popup_content ();
  button

let%shared sign_in_button ?(a_placeholder_email = "Your email")
    ?(a_placeholder_phone = "Or your phone")
    ?(a_placeholder_pwd = "Your password")
    ?(text_keep_me_logged_in = "keep me logged in") ?(text_sign_in = "Sign in")
    ?(content_popup_forgotpwd = "Recover password")
    ?(text_button_forgotpwd = "Forgot your password?")
    ?(text_button = "Sign in") ?(text_send_button = "Send") ()
  =
  let popup_content =
    [%client
      fun close ->
        Lwt.return
        @@ div
             [ h2 [txt ~%text_button]
             ; connect_form ~a_placeholder_email:~%a_placeholder_email
                 ~a_placeholder_phone:~%a_placeholder_phone
                 ~a_placeholder_pwd:~%a_placeholder_pwd
                 ~text_keep_me_logged_in:~%text_keep_me_logged_in
                 ~text_sign_in:~%text_sign_in ()
             ; forgotpwd_button ~content_popup:~%content_popup_forgotpwd
                 ~text_button:~%text_button_forgotpwd
                 ~text_send_button:~%text_send_button
                 ~close:(fun () -> Lwt.async close)
                 () ]]
  in
  let button_name = text_button in
  let button =
    D.button ~a:[a_class ["button"; "os-sign-in-btn"]] [txt button_name]
  in
  bind_popup_button ~a:[a_class ["os-sign-in"]] ~button ~popup_content ();
  button

let%shared sign_up_button ?(a_placeholder_email = "Your email")
    ?(a_placeholder_phone = "or your phone") ?(text_button = "Sign up")
    ?(text_send_button = "Send") ()
  =
  let popup_content =
    [%client
      fun _ ->
        let l =
          [ h2 [txt ~%text_button]
          ; sign_up_form ~a_placeholder_email:~%a_placeholder_email
              ~text:~%text_send_button () ]
        in
        Lwt.return @@ div
        @@
        if !enable_phone
        then
          l
          @ [ sign_up_by_phone_input ~placeholder:~%a_placeholder_phone
                ~%text_send_button ]
        else l]
  in
  let button =
    D.button ~a:[a_class ["button"; "os-sign-up-btn"]] [txt text_button]
  in
  bind_popup_button ~a:[a_class ["os-sign-up"]] ~button ~popup_content ();
  button

let%shared disconnect_link ?(text_logout = "Logout") ?(a = []) () =
  Eliom_content.Html.D.Raw.a
    ~a:
      (a_onclick
         [%client
           fun _ ->
             Lwt.async (fun () ->
               Eliom_client.change_page ~service:Os_services.disconnect_service
                 () ())]
      :: a)
    [Os_icons.F.signout (); txt text_logout]

let%shared connected_user_box ~user =
  let username = username user in
  D.div ~a:[a_class ["connected-user-box"]] [avatar user; div [username]]

let%shared connection_box ?(a_placeholder_email = "Your email")
    ?(a_placeholder_phone = "Your phone") ?(a_placeholder_pwd = "Your password")
    ?(text_keep_me_logged_in = "keep me logged in")
    ?(content_popup_forgotpwd = "Recover password")
    ?(text_button_forgotpwd = "Forgot your password?")
    ?(text_sign_in = "Sign in") ?(text_sign_up = "Sign up")
    ?(text_send_button = "Send") ()
  =
  let sign_in =
    sign_in_button ~a_placeholder_email ~a_placeholder_phone ~a_placeholder_pwd
      ~text_keep_me_logged_in ~text_sign_in ~content_popup_forgotpwd
      ~text_button_forgotpwd ~text_button:text_sign_in ~text_send_button ()
  in
  let sign_up =
    sign_up_button ~a_placeholder_email ~text_button:text_sign_up
      ~text_send_button ()
  in
  Lwt.return @@ div ~a:[a_class ["os-connection-box"]] [sign_in; sign_up]

let%shared user_box ?(a_placeholder_email = "Your email")
    ?(a_placeholder_pwd = "Your password")
    ?(text_keep_me_logged_in = "keep me logged in")
    ?(content_popup_forgotpwd = "Recover password")
    ?(text_button_forgotpwd = "Forgot your password?")
    ?(text_sign_in = "Sign in") ?(text_sign_up = "Sign up")
    ?(text_send_button = "Send") ?user ()
  =
  match user with
  | None ->
      connection_box ~a_placeholder_email ~a_placeholder_pwd
        ~text_keep_me_logged_in ~content_popup_forgotpwd ~text_button_forgotpwd
        ~text_sign_in ~text_sign_up ~text_send_button ()
  | Some user -> Lwt.return (connected_user_box ~user)

let%shared enable_phone () = enable_phone := true
