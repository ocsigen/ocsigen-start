{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

let rec main_service_fallback uid gp pp exc =
  let open Ebapp.Page in
  match exc with
  | Ebapp.Session.Not_connected ->
      (** The following correspond to the home page on when disconnected. *)
      Lwt.return (%%%MODULE_NAME%%%_container.page [
        div ~a:[a_id "%%%PROJECT_NAME%%%-forms"] [
          div ~a:[a_class ["left-bar"]] [
            b [pcdata "Sign in:"];
            hr ();
            p [pcdata "You can sign in if you have already an account:"];
            %%%MODULE_NAME%%%_view.connect_form ();
            a ~service:%%%MODULE_NAME%%%_services.forgot_password_service [
              pcdata "Forgot your password?";
            ] ();
          ];
          p [b [pcdata "OR"]];
          div ~a:[a_class ["left-bar"]] [
            b [pcdata "Sign up:"];
            hr ();
            p [pcdata "Just sign up to our awesome application!"];
            %%%MODULE_NAME%%%_view.sign_up_form ();
          ];
          p [b [pcdata "OR"]];
          div ~a:[a_class ["left-bar"]] [
            b [pcdata "Preregister:"];
            hr ();
            p [
              pcdata "If you are interested by our application,";
              pcdata " please let us your email address!";
            ];
            %%%MODULE_NAME%%%_view.preregister_form ();
          ];
        ];
        div ~a:[a_class ["clear"]] [];
      ])
  | _ -> Lwt.return (%%%MODULE_NAME%%%_container.page [])

let main_service_handler uid gp pp =
  let open %%%MODULE_NAME%%%_user in
  lwt user = %%%MODULE_NAME%%%_user.user_of_uid uid in
  let crop = (D.div [pcdata "start cropping"]) in
  %%%MODULE_NAME%%%_image.start_crop_on_clicking_on
    crop
    (user);
  lwt email = %%%MODULE_NAME%%%_user.email_of_uid uid in
  Lwt.return (%%%MODULE_NAME%%%_container.page ~user (
    if (user.fn = "" || user.ln = "")
    then [%%%MODULE_NAME%%%_view.information_form ()]
    else [
      pcdata "welcome !";
      D.p [pcdata email];
      crop;
    ];
  ))

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
  let act_key' = F.make_string_uri ~absolute:true ~service act_key in
  print_endline act_key';
  (if send_email then try
       Ebapp.Email.send
         ~to_addrs:[(email, "")]
         ~subject:"creation"
         [
           "you activation key: "; act_key'; "do not reply";
         ]
     with _ -> ());
  act_key

let sign_up_handler' () email =
  lwt is_registered = %%%MODULE_NAME%%%_user.is_registered email in
  if is_registered then begin
    ignore (%%%MODULE_NAME%%%_reqm.(error_string "This user already exists"));
    Lwt.return ()
  end else begin
    let act_key = generate_act_key ~service:%%%MODULE_NAME%%%_services.main_service email in
    lwt uid = %%%MODULE_NAME%%%_user.create ~firstname:"" ~lastname:"" email in
    lwt () = %%%MODULE_NAME%%%_user.add_activationkey ~act_key uid in
    Lwt.return ()
  end

let forgot_password_handler () () =
  Lwt.return (%%%MODULE_NAME%%%_container.page [
    div ~a:[a_id "%%%PROJECT_NAME%%%-forms"] [
      div ~a:[a_class ["left-bar"]] [
        p [pcdata "Enter your email to get an activation link to access to your account!"];
        %%%MODULE_NAME%%%_view.forgot_password_form ();
      ];
    ]
  ])

let forgot_password_handler' () email =
  try_lwt
    lwt uid = %%%MODULE_NAME%%%_user.uid_of_email email in
    let act_key = generate_act_key ~service:%%%MODULE_NAME%%%_services.main_service email in
    %%%MODULE_NAME%%%_user.add_activationkey ~act_key uid
  with %%%MODULE_NAME%%%_db.No_such_resource ->
    %%%MODULE_NAME%%%_reqm.(error_string "This user does not exists");
    Lwt.return ()

let about_handler () () =
  Lwt.return (%%%MODULE_NAME%%%_container.page [
    div [
      p [pcdata "This template provides you a skeleton for an ocsigen application."];
      hr ();
      p [pcdata "Feel free to modify the code."]
    ]
  ])

let disconnect_handler () () =
  (* SECURITY: no check here because we disconnect the session cookie owner. *)
  lwt () = Ebapp.Session.disconnect () in
  lwt () = Eliom_state.discard ~scope:Eliom_common.default_session_scope () in
  lwt () = Eliom_state.discard ~scope:Eliom_common.default_process_scope () in
  lwt () = Eliom_state.discard ~scope:Eliom_common.request_scope () in
  Lwt.return ()

let connect_handler () (login, pwd) =
  (* SECURITY: no check here. *)
  lwt () = disconnect_handler () () in
  try_lwt
    lwt uid = %%%MODULE_NAME%%%_user.verify_password login pwd in
    Ebapp.Session.connect uid
  with %%%MODULE_NAME%%%_db.No_such_resource ->
    %%%MODULE_NAME%%%_reqm.(error_string "Your password does not match.");
    Lwt.return ()

let activation_handler akey () =
  (* SECURITY: we disconnect the user before doing anything
   * moreover in this case, if the user is already disconnect
   * we're going to disconnect him even if the actionvation key
   * is outdated. *)
  lwt () = Ebapp.Session.disconnect () in
  try_lwt
    lwt uid = %%%MODULE_NAME%%%_user.uid_of_activationkey akey in
    lwt () = Ebapp.Session.connect uid in
    Eliom_registration.Redirection.send Eliom_service.void_coservice'
  with %%%MODULE_NAME%%%_db.No_such_resource ->
    %%%MODULE_NAME%%%_reqm.(notice_string "An activation key has been created");
    Eliom_registration.Action.send ()

          (*
let admin_service_handler uid gp pp =
  lwt user = %%%MODULE_NAME%%%_user.user_of_uid uid in
  (*lwt cnt = Ebapp.Admin.admin_page_content user in*)
  Lwt.return (%%%MODULE_NAME%%%_container.page [
  ] (*@ cnt*) )
           *)

let preregister_handler' () email =
  lwt is_preregistered = %%%MODULE_NAME%%%_user.is_preregistered email in
  lwt is_registered = %%%MODULE_NAME%%%_user.is_registered email in
  Printf.printf "%b:%b%!\n" is_preregistered is_registered;
  if not (is_preregistered || is_registered)
   then %%%MODULE_NAME%%%_user.add_preregister email
   else begin
     ignore (%%%MODULE_NAME%%%_reqm.(error_string "Email already uses"));
     Lwt.return ()
   end

let () =
  Ebapp.App.register
    (%%%MODULE_NAME%%%_services.main_service)
    (Ebapp.Page.connected_page
       ~fallback:main_service_fallback
       main_service_handler);

  Ebapp.App.register
    (%%%MODULE_NAME%%%_services.forgot_password_service)
    (Ebapp.Page.page
       forgot_password_handler);

  Ebapp.App.register
    (%%%MODULE_NAME%%%_services.about_service)
    (Ebapp.Page.page
       about_handler);

  Eliom_registration.Action.register
    (%%%MODULE_NAME%%%_services.set_personal_data_service')
    (Ebapp.Session.connected_fun
       set_personal_data_handler');

  Eliom_registration.Action.register
    (%%%MODULE_NAME%%%_services.forgot_password_service')
    (forgot_password_handler');

  Eliom_registration.Action.register
    (%%%MODULE_NAME%%%_services.preregister_service')
    (preregister_handler');

  Eliom_registration.Action.register
    (%%%MODULE_NAME%%%_services.sign_up_service')
    (sign_up_handler');

  Eliom_registration.Action.register
    (%%%MODULE_NAME%%%_services.connect_service)
    (connect_handler);

  Eliom_registration.Action.register
    (%%%MODULE_NAME%%%_services.disconnect_service)
    (disconnect_handler);

  Eliom_registration.Any.register
    (%%%MODULE_NAME%%%_services.activation_service)
    (activation_handler)
