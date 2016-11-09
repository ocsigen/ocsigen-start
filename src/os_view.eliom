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

[%%shared
  open Eliom_content.Html
  open Eliom_content.Html.F
]

let%client check_password_confirmation ~password ~confirmation =
  let password_dom = To_dom.of_input password in
  let confirmation_dom = To_dom.of_input confirmation in
  Lwt_js_events.async
    (fun () ->
       Lwt_js_events.inputs confirmation_dom
         (fun _ _ ->
            ignore
              (if Js.to_string password_dom##.value <> Js.to_string
              confirmation_dom##.value
               then
                 (Js.Unsafe.coerce
                    confirmation_dom)##(setCustomValidity ("Passwords do not match"))
               else (Js.Unsafe.coerce confirmation_dom)##(setCustomValidity ("")));
            Lwt.return ()))

let%shared generic_email_form ?a ?label ?(text="Send") ?(email="") ~service () =
  D.Form.post_form ?a ~service
    (fun name ->
      let l = [
        Form.input
          ~a:[a_placeholder "e-mail address"]
          ~input_type:`Email
          ~value:email
          ~name
          Form.string;
        Form.input
          ~a:[a_class ["button"]]
          ~input_type:`Submit
          ~value:text
          Form.string;
      ]
      in
      match label with
      | None -> l
      | Some lab -> F.label [pcdata lab]::l) ()

let%shared connect_form ?a ?(email="") () =
  D.Form.post_form ?a ~xhr:false ~service:Os_services.connect_service
    (fun ((login, password), keepmeloggedin) -> [
      Form.input
        ~a:[a_placeholder "Your email"]
        ~name:login
        ~input_type:`Email
        ~value:email
        Form.string;
      Form.input
        ~a:[a_placeholder "Your password"]
        ~name:password
        ~input_type:`Password
        Form.string;
      Form.bool_checkbox_one
        ~a:[a_checked ()]
        ~name:keepmeloggedin
        ();
      span [pcdata "keep me logged in"];
      Form.input
        ~a:[a_class ["button" ; "os-sign-in"]]
        ~input_type:`Submit
        ~value:"Sign in"
        Form.string;
    ]) ()

let%shared disconnect_button ?a () =
  Form.post_form ?a ~service:Os_services.disconnect_service
    (fun _ -> [
         Form.button_no_value
           ~a:[ a_class ["button"] ]
           ~button_type:`Submit
           [Os_icons.F.signout (); pcdata "Logout"]
       ]) ()

let%shared sign_up_form ?a ?email () =
  generic_email_form ?a ?email ~service:Os_services.sign_up_service ()

let%shared forgot_password_form ?a () =
  generic_email_form ?a
    ~service:Os_services.forgot_password_service ()

let%shared information_form ?a
    ?(firstname="") ?(lastname="") ?(password1="") ?(password2="")
    () =
  D.Form.post_form ?a ~service:Os_services.set_personal_data_service
    (fun ((fname, lname), (passwordn1, passwordn2)) ->
       let pass1 = D.Form.input
           ~a:[a_placeholder "Your password"]
           ~name:passwordn1
           ~value:password1
           ~input_type:`Password
           Form.string
       in
       let pass2 = D.Form.input
           ~a:[a_placeholder "Re-enter password"]
           ~name:passwordn2
           ~value:password2
           ~input_type:`Password
           Form.string
       in
       let _ = [%client (
         check_password_confirmation ~password:~%pass1 ~confirmation:~%pass2
       : unit)]
       in
       [
         Form.input
           ~a:[a_placeholder "Your first name"]
           ~name:fname
           ~value:firstname
           ~input_type:`Text
           Form.string;
         Form.input
           ~a:[a_placeholder "Your last name"]
           ~name:lname
           ~value:lastname
           ~input_type:`Text
           Form.string;
         pass1;
         pass2;
         Form.input
           ~a:[a_class ["button"]]
           ~input_type:`Submit
           ~value:"Submit"
           Form.string;
       ]) ()

let%shared preregister_form ?a label =
  generic_email_form ?a ~service:Os_services.preregister_service ~label ()

let%shared home_button ?a () =
  Form.get_form ?a ~service:Os_services.main_service
    (fun _ -> [
      Form.input
        ~input_type:`Submit
        ~value:"home"
        Form.string;
    ])

let%shared avatar user =
  match Os_user.avatar_uri_of_user user with
  | Some src ->
    img ~alt:"picture" ~a:[a_class ["os_avatar"]] ~src ()
  | None -> Os_icons.F.user ()

let%shared username user =
  let n = match Os_user.firstname_of_user user with
    | "" ->
      let userid = Os_user.userid_of_user user in
      [pcdata ("User "^Int64.to_string userid)]
    | s ->
      [pcdata s;
       pcdata " ";
       pcdata (Os_user.lastname_of_user user);
      ]
  in
  div ~a:[a_class ["os_username"]] n

let%shared password_form ?a ~service () =
  D.Form.post_form
    ?a
    ~service
    (fun (pwdn, pwd2n) ->
       let pass1 =
         D.Form.input
           ~a:[a_required ();
               a_autocomplete false]
           ~input_type:`Password ~name:pwdn
           Form.string
       in
       let pass2 =
         D.Form.input
           ~a:[a_required ();
               a_autocomplete false]
           ~input_type:`Password ~name:pwd2n
           Form.string
       in
       ignore [%client (
        check_password_confirmation ~password:~%pass1 ~confirmation:~%pass2
       : unit)];
       [
         table
           [
             tr [td [label [pcdata "Password:"]]; td [pass1]];
             tr [td [label [pcdata "Retype password:"]]; td [pass2]];
           ];
         Form.input ~input_type:`Submit
           ~a:[ a_class [ "button" ] ] ~value:"Send" Form.string
       ])
    ()
