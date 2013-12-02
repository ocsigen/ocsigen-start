{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

let rec main_service_fallback uid gp pp exc =
  let open Ebapp.Page in
  match exc with
  | Ebapp.Session.Not_connected ->
      (** The following correspond to the home page on when disconnected. *)
      Lwt.return (Foobar_container.page [
        div ~a:[a_id "foobar-forms"] [
          div ~a:[a_class ["left-bar"]] [
            b [pcdata "Sign in:"];
            hr ();
            p [pcdata "You can sign in if you have already an account:"];
            Foobar_view.connect_form ();
            a ~service:Foobar_services.forgot_password_service [
              pcdata "Forgot your password?";
            ] ();
          ];
          p [b [pcdata "OR"]];
          div ~a:[a_class ["left-bar"]] [
            b [pcdata "Sign up:"];
            hr ();
            p [pcdata "Just sign up to our awesome application!"];
            Foobar_view.sign_up_form ();
          ];
        ];
        div ~a:[a_class ["clear"]] [];
      ])
  | _ -> Lwt.return (Foobar_container.page [])

let main_service_handler uid gp pp =
  let open Foobar_user in
  lwt user = Foobar_user.user_of_uid uid in
  let crop = (D.div [pcdata "start cropping"]) in
  Foobar_image.start_crop_on_clicking_on
    crop
    (user);
  Lwt.return (Foobar_container.page ~user [
    if (user.fn = "" || user.ln = "")
    then Foobar_view.information_form ()
    else (
      pcdata "welcome !";
      crop;
    );
  ])

let set_personal_data_handler' uid ()
    (((firstname, lastname), (pwd, pwd2)) as pd) =
  if firstname = "" || lastname = "" || pwd <> pwd2
  then
    (Foobar_reqm.(set wrong_pdata pd);
     Lwt.return ())
  else (
    lwt user = Foobar_user.user_of_uid uid in
    let open Foobar_user in
    let record = {
      user with
      fn = firstname;
      ln = lastname;
    } in
    Foobar_user.update' ~password:pwd record)

let generate_act_key
    ?(act_key = Ocsigen_lib.make_cryptographic_safe_string ())
    ?(send_email = true)
    ~service
    email =
  let service =
    Eliom_service.attach_coservice' ~fallback:service
      ~service:Foobar_services.activation_service
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
  try_lwt
    lwt _ = Foobar_user.uid_of_email email in
    let s = Foobar_reqm.(error_string "This user already exists") in
    Lwt.return ()
  with Foobar_db.No_such_resource ->
    let act_key = generate_act_key ~service:Foobar_services.main_service email in
    lwt uid = Foobar_user.create ~firstname:"" ~lastname:"" email in
    lwt () = Foobar_user.add_activationkey ~act_key uid in
    Lwt.return ()

let forgot_password_handler () () =
  Lwt.return (Foobar_container.page [
    div ~a:[a_id "foobar-forms"] [
      div ~a:[a_class ["left-bar"]] [
        p [pcdata "Enter your email to get an activation link to access to your account!"];
        Foobar_view.forgot_password_form ();
      ];
    ]
  ])

let forgot_password_handler' () email =
  try_lwt
    lwt uid = Foobar_user.uid_of_email email in
    let act_key = generate_act_key ~service:Foobar_services.main_service email in
    Foobar_user.add_activationkey ~act_key uid
  with Foobar_db.No_such_resource ->
    Foobar_reqm.(error_string "This user does not exists");
    Lwt.return ()

let about_handler () () =
  Lwt.return (Foobar_container.page [
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
    lwt uid = Foobar_user.verify_password login pwd in
    Ebapp.Session.connect uid
  with Foobar_db.No_such_resource ->
    Foobar_reqm.(error_string "Your password does not match.");
    Lwt.return ()

let activation_handler akey () =
  (* SECURITY: we disconnect the user before doing anything
   * moreover in this case, if the user is already disconnect
   * we're going to disconnect him even if the actionvation key
   * is outdated. *)
  lwt () = Ebapp.Session.disconnect () in
  try_lwt
    lwt uid = Foobar_user.uid_of_activationkey akey in
    lwt () = Ebapp.Session.connect uid in
    Eliom_registration.Redirection.send Eliom_service.void_coservice'
  with Foobar_db.No_such_resource ->
    Foobar_reqm.(notice_string "An activation key has been created");
    Eliom_registration.Action.send ()

          (*
let admin_service_handler uid gp pp =
  lwt user = Foobar_user.user_of_uid uid in
  (*lwt cnt = Ebapp.Admin.admin_page_content user in*)
  Lwt.return (Foobar_container.page [
  ] (*@ cnt*) )
           *)

let () =
  Ebapp.App.register
    (Foobar_services.main_service)
    (Ebapp.Page.connected_page
       ~fallback:main_service_fallback
       main_service_handler);

  Ebapp.App.register
    (Foobar_services.forgot_password_service)
    (Ebapp.Page.page
       forgot_password_handler);

  Ebapp.App.register
    (Foobar_services.about_service)
    (Ebapp.Page.page
       about_handler);

  Eliom_registration.Action.register
    (Foobar_services.set_personal_data_service')
    (Ebapp.Session.connected_fun
       set_personal_data_handler');

  Eliom_registration.Action.register
    (Foobar_services.forgot_password_service')
    (forgot_password_handler');

  Eliom_registration.Action.register
    (Foobar_services.sign_up_service')
    (sign_up_handler');

  Eliom_registration.Action.register
    (Foobar_services.connect_service)
    (connect_handler);

  Eliom_registration.Action.register
    (Foobar_services.disconnect_service)
    (disconnect_handler);

  Eliom_registration.Any.register
    (Foobar_services.activation_service)
    (activation_handler)
