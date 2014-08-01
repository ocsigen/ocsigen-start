{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

let main_service_handler uid_o gp pp =
  %%%MODULE_NAME%%%_container.page uid_o (
    [
     p [em [pcdata "Eliom base app: Put here the app content."]]
    ]
  )

let set_personal_data_handler' uid ()
    (((firstname, lastname), (pwd, pwd2)) as pd) =
  if firstname = "" || lastname = "" || pwd <> pwd2
  then
    (%%%MODULE_NAME%%%_reqm.(set wrong_pdata pd);
     Lwt.return ())
  else (
    lwt user = %%%MODULE_NAME%%%_user.user_of_uid uid in
    let open %%%MODULE_NAME%%%_user in
    let record = {
      user with
      fn = firstname;
      ln = lastname;
    } in
    %%%MODULE_NAME%%%_user.update' ~password:pwd record)

let generate_act_key
    ?(act_key = Ocsigen_lib.make_cryptographic_safe_string ())
    ?(send_email = true)
    ~service
    email =
  let service =
    Eliom_service.attach_coservice' ~fallback:service
      ~service:%%%MODULE_NAME%%%_services.activation_service
  in
  let act_link = F.make_string_uri ~absolute:true ~service act_key in
  (* For debugging we print the activation link on standard output
     to make possible to connect even if the mail transport is not
     configured. REMOVE! *)
  print_endline act_link;
  (if send_email then try
       Ebapp.Email.send
         ~to_addrs:[(email, "")]
         ~subject:"creation"
         [
           "To confirm your e-mail address, please click on this link: ";
           act_link;
         ]
     with _ -> ());
  act_key

let sign_up_handler' () email =
  lwt is_registered = %%%MODULE_NAME%%%_user.is_registered email in
  if is_registered then begin
    Eliom_reference.Volatile.set %%%MODULE_NAME%%%_reqm.user_already_exists true;
    Lwt.return ()
  end else begin
    let act_key =
      generate_act_key ~service:%%%MODULE_NAME%%%_services.main_service email in
    lwt uid = %%%MODULE_NAME%%%_user.create ~firstname:"" ~lastname:"" email in
    Eliom_reference.Volatile.set %%%MODULE_NAME%%%_reqm.activation_key_created true;
    %%%MODULE_NAME%%%_reqm.(notice_string
                  "An activation link has been sent to your e-mail.");
    lwt () = %%%MODULE_NAME%%%_user.add_activationkey ~act_key uid in
    Lwt.return ()
  end

let forgot_password_handler uid_o () () =
  %%%MODULE_NAME%%%_container.page uid_o [
    div ~a:[a_id "%%%PROJECT_NAME%%%-forms"] [
      div ~a:[a_class ["eba-box"]] [
        p [pcdata "Enter your e-mail address to receive an activation link \
                   to access to your account:"];
        %%%MODULE_NAME%%%_view.forgot_password_form ();
      ];
    ]
  ]

let forgot_password_handler' () email =
  try_lwt
    lwt uid = %%%MODULE_NAME%%%_user.uid_of_email email in
    let act_key =
      generate_act_key ~service:%%%MODULE_NAME%%%_services.main_service email in
    Eliom_reference.Volatile.set %%%MODULE_NAME%%%_reqm.activation_key_created true;
    %%%MODULE_NAME%%%_user.add_activationkey ~act_key uid
  with %%%MODULE_NAME%%%_db.No_such_resource ->
    Eliom_reference.Volatile.set %%%MODULE_NAME%%%_reqm.user_does_not_exist true;
    Lwt.return ()

let about_handler uid_o () () =
  %%%MODULE_NAME%%%_container.page uid_o [
    div [
      p [pcdata "This template provides a skeleton \
                 for an Ocsigen application."];
      hr ();
      p [pcdata "Feel free to modify the generated code and use it \
                 or redistribute it as you want."]
    ]
  ]

let disconnect_handler () () =
  (* SECURITY: no check here because we disconnect the session cookie owner. *)
  lwt () = Ebapp.Session.disconnect () in
  lwt () = Eliom_state.discard ~scope:Eliom_common.default_session_scope () in
  lwt () = Eliom_state.discard ~scope:Eliom_common.default_process_scope () in
  lwt () = Eliom_state.discard ~scope:Eliom_common.request_scope () in
  Lwt.return ()

let connect_handler () (login, pwd) =
  (* SECURITY: no check here.
     We disconnect the user in any case, so that he does not believe
     to be connected with the new account if the password is wrong. *)
  lwt () = disconnect_handler () () in
  try_lwt
    lwt uid = %%%MODULE_NAME%%%_user.verify_password login pwd in
    Ebapp.Session.connect uid
  with %%%MODULE_NAME%%%_db.No_such_resource ->
    Eliom_reference.Volatile.set %%%MODULE_NAME%%%_reqm.wrong_password true;
    Lwt.return ()

let activation_handler akey () =
  (* SECURITY: we disconnect the user before doing anything. *)
  (* If the user is already connected,
     we're going to disconnect him even if the activation key outdated. *)
  lwt () = Ebapp.Session.disconnect () in
  try_lwt
    lwt uid = %%%MODULE_NAME%%%_user.uid_of_activationkey akey in
    lwt () = Ebapp.Session.connect uid in
    Eliom_registration.Redirection.send Eliom_service.void_coservice'
  with %%%MODULE_NAME%%%_db.No_such_resource ->
    Eliom_reference.Volatile.set %%%MODULE_NAME%%%_reqm.activation_key_outdated true;
    (*VVV This should be a redirection, in order to erase the outdated URL.
      But we do not have a simple way of
      writing an error message after a redirection for now.*)
    Eliom_registration.Action.send ()

          (*
let admin_service_handler uid gp pp =
  lwt user = %%%MODULE_NAME%%%_user.user_of_uid uid in
  (*lwt cnt = Ebapp.Admin.admin_page_content user in*)
  %%%MODULE_NAME%%%_container.page [
  ] (*@ cnt*)
           *)

let preregister_handler' () email =
  lwt is_preregistered = %%%MODULE_NAME%%%_user.is_preregistered email in
  lwt is_registered = %%%MODULE_NAME%%%_user.is_registered email in
  Printf.printf "%b:%b%!\n" is_preregistered is_registered;
  if not (is_preregistered || is_registered)
   then %%%MODULE_NAME%%%_user.add_preregister email
   else begin
     Eliom_reference.Volatile.set %%%MODULE_NAME%%%_reqm.user_already_preregistered true;
     Lwt.return ()
   end

let () =
  Ebapp.App.register
    %%%MODULE_NAME%%%_services.main_service
    (Ebapp.Page.Opt.connected_page main_service_handler);

  Ebapp.App.register
    %%%MODULE_NAME%%%_services.forgot_password_service
    (Ebapp.Page.Opt.connected_page forgot_password_handler);

  Ebapp.App.register
    %%%MODULE_NAME%%%_services.about_service
    (Ebapp.Page.Opt.connected_page about_handler);

  Eliom_registration.Action.register
    %%%MODULE_NAME%%%_services.set_personal_data_service'
    (Ebapp.Session.connected_fun set_personal_data_handler');

  Eliom_registration.Action.register
    %%%MODULE_NAME%%%_services.forgot_password_service'
    (forgot_password_handler');

  Eliom_registration.Action.register
    %%%MODULE_NAME%%%_services.preregister_service'
    (preregister_handler');

  Eliom_registration.Action.register
    %%%MODULE_NAME%%%_services.sign_up_service'
    (sign_up_handler');

  Eliom_registration.Action.register
    %%%MODULE_NAME%%%_services.connect_service
    (connect_handler);

  Eliom_registration.Action.register
    %%%MODULE_NAME%%%_services.disconnect_service
    (disconnect_handler);

  Eliom_registration.Any.register
    %%%MODULE_NAME%%%_services.activation_service
    (activation_handler)
