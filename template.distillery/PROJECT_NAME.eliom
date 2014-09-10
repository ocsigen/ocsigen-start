{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

let main_service_handler uid_o gp pp =
  %%%MODULE_NAME%%%_container.page uid_o (
    [
     p [em [pcdata "Eliom base app: Put app content here."]]
    ]
  )

let set_personal_data_handler' uid ()
    (((firstname, lastname), (pwd, pwd2)) as pd) =
  if firstname = "" || lastname = "" || pwd <> pwd2
  then
    (Eliom_reference.Volatile.set Eba_msg.wrong_pdata (Some pd);
     Lwt.return ())
  else (
    lwt user = Eba_user.user_of_uid uid in
    let open Eba_user in
    let record = {
      user with
      fn = firstname;
      ln = lastname;
    } in
    Eba_user.update' ~password:pwd record)

let set_password_handler' uid () (pwd, pwd2) =
  if pwd <> pwd2
  then
    (Eba_msg.msg ~level:`Err "Passwords do not match";
     Lwt.return ())
  else (
    lwt user = Eba_user.user_of_uid uid in
    Eba_user.update' ~password:pwd user)

let generate_act_key
    ?(act_key = Ocsigen_lib.make_cryptographic_safe_string ())
    ?(send_email = true)
    ~service
    email =
  let service =
    Eliom_service.attach_coservice' ~fallback:service
      ~service:Eba_services.activation_service
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
  lwt is_registered = Eba_user.is_registered email in
  if is_registered then begin
    Eliom_reference.Volatile.set
      Eba_userbox.user_already_exists true;
    Lwt.return ()
  end else begin
    let act_key =
      generate_act_key ~service:Eba_services.main_service email in
    lwt uid = Eba_user.create ~firstname:"" ~lastname:"" email in
    Eliom_reference.Volatile.set Eba_msg.activation_key_created true;
    lwt () = Eba_user.add_activationkey ~act_key uid in
    Lwt.return ()
  end

let forgot_password_handler uid_o () () =
  %%%MODULE_NAME%%%_container.page uid_o [
    div ~a:[a_id "%%%PROJECT_NAME%%%-forms"] [
      div ~a:[a_class ["eba-box"]] [
        p [pcdata "Enter your e-mail address to receive an activation link \
                   to access to your account:"];
        Eba_view.forgot_password_form ();
      ];
    ]
  ]

let forgot_password_handler' () email =
  try_lwt
    lwt uid = Eba_user.uid_of_email email in
    let act_key =
      generate_act_key ~service:Eba_services.main_service email in
    Eliom_reference.Volatile.set Eba_msg.activation_key_created true;
    Eba_user.add_activationkey ~act_key uid
  with Eba_db.No_such_resource ->
    Eliom_reference.Volatile.set
      Eba_userbox.user_does_not_exist true;
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
  Eba_session.disconnect ()

let connect_handler () (login, pwd) =
  (* SECURITY: no check here.
     We disconnect the user in any case, so that he does not believe
     to be connected with the new account if the password is wrong. *)
  lwt () = disconnect_handler () () in
  try_lwt
    lwt uid = Eba_user.verify_password login pwd in
    Eba_session.connect uid
  with Eba_db.No_such_resource ->
    Eliom_reference.Volatile.set Eba_userbox.wrong_password true;
    Lwt.return ()

let activation_handler akey () =
  (* SECURITY: we disconnect the user before doing anything. *)
  (* If the user is already connected,
     we're going to disconnect him even if the activation key outdated. *)
  lwt () = Eba_session.disconnect () in
  try_lwt
    lwt uid = Eba_user.uid_of_activationkey akey in
    lwt () = Eba_session.connect uid in
    Eliom_registration.Redirection.send Eliom_service.void_coservice'
  with Eba_db.No_such_resource ->
    Eliom_reference.Volatile.set
      Eba_userbox.activation_key_outdated true;
    (*VVV This should be a redirection, in order to erase the outdated URL.
      But we do not have a simple way of
      writing an error message after a redirection for now.*)
    Eliom_registration.Action.send ()

          (*
let admin_service_handler uid gp pp =
  lwt user = Eba_user.user_of_uid uid in
  (*lwt cnt = Ebapp.Admin.admin_page_content user in*)
  %%%MODULE_NAME%%%_container.page [
  ] (*@ cnt*)
           *)

let preregister_handler' () email =
  lwt is_preregistered = Eba_user.is_preregistered email in
  lwt is_registered = Eba_user.is_registered email in
  Printf.printf "%b:%b%!\n" is_preregistered is_registered;
  if not (is_preregistered || is_registered)
   then Eba_user.add_preregister email
   else begin
     Eliom_reference.Volatile.set
       Eba_userbox.user_already_preregistered true;
     Lwt.return ()
   end

let () =
  Ebapp.App.register
    Eba_services.main_service
    (Ebapp.Page.Opt.connected_page main_service_handler);

  Ebapp.App.register
    Eba_services.forgot_password_service
    (Ebapp.Page.Opt.connected_page forgot_password_handler);

  Ebapp.App.register
    Eba_services.about_service
    (Ebapp.Page.Opt.connected_page about_handler);

  Eliom_registration.Action.register
    Eba_services.set_personal_data_service'
    (Eba_session.connected_fun set_personal_data_handler');

  Eliom_registration.Action.register
    Eba_services.set_password_service'
    (Eba_session.connected_fun set_password_handler');

  Eliom_registration.Action.register
    Eba_services.forgot_password_service'
    forgot_password_handler';

  Eliom_registration.Action.register
    Eba_services.preregister_service'
    preregister_handler';

  Eliom_registration.Action.register
    Eba_services.sign_up_service'
    sign_up_handler';

  Eliom_registration.Action.register
    Eba_services.connect_service
    connect_handler;

  Eliom_registration.Action.register
    Eba_services.disconnect_service
    disconnect_handler;

  Eliom_registration.Any.register
    Eba_services.activation_service
    activation_handler
