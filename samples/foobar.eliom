{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

let main_service_fallback uid gp pp exc =
  if (Int64.to_int uid) = -1
  then (* not connected *)
    (** The following correspond to the home page on when disconnected. *)
    Lwt.return (Foobar_container.page [
        div ~a:[a_id "foobar-forms"] [
          div ~a:[a_class ["left-bar"]] [
            b [
              pcdata "Sign in:";
            ];
            hr ();
            p [
              pcdata "You can sign in if you have already an account:";
            ];
            Foobar_view.connect_form ();
            a ~service:Foobar_services.forgot_password_service [
              pcdata "Forgot your password?";
            ] ();
          ];
          p [
            b [pcdata "OR";]
          ];
          div ~a:[a_class ["left-bar"]] [
            b [
              pcdata "Sign up:";
            ];
            hr ();
            p [
              pcdata "Just sign up to our awesome application!";
            ];
            Foobar_view.sign_up_form ();
          ];
        ];
        div ~a:[a_class ["clear"]] [];
    ])
  else (* connected *)
    Lwt.return (Foobar_container.page [
    ])

let main_service_handler uid gp pp =
  let open Ebapp.User in
  let open Foobar_types.User in
  let open Foobar_user in
  lwt user = Ebapp.User.user_of_uid uid in
  let ext = Ebapp.User.ext_of_user user in
  lwt () =
    Ebapp.Groups.add_user
      ~group:Ebapp.Groups.admin
      ~userid:(Ebapp.User.uid_of_user user)
  in
  Lwt.return (Foobar_container.page ~user [
    if (ext.fn = "" || ext.ln = "")
    then Foobar_view.information_form ()
    else (
      pcdata "welcome !";
    );
  ])

let set_personal_data_handler' userid ()
    (((firstname, lastname), (pwd, pwd2)) as pd) =
  (* SECURITY: We get the userid from session cookie,
     and change personal data for this user. No other check. *)
  if firstname = "" || lastname = "" || pwd <> pwd2
  then
    (Ebapp.R.Error.push (`Wrong_personal_data pd);
     Lwt.return ())
  else (
    lwt u = Ebapp.User.user_of_uid userid in
    let open Eba_types.User in
    let open Foobar_types.User in
    let ext = {
        fn = firstname;
        ln = lastname;
    } in
    let record = {
      uid = userid;
      ext = ext;
    } in
    Ebapp.User.update ~password:pwd record)

let sign_up_handler' () email =
  match_lwt Ebapp.User.uid_of_email email with
    | None ->
        let open Foobar_types.User in
        lwt _ =
          Ebapp.User.create ~service:Foobar_services.main_service ~email
            {fn = ""; ln = ""}
        in
        Lwt.return ()
    | Some _ ->
        Ebapp.Rmsg.Error.push (`User_already_exists email);
        Lwt.return ()

let forgot_password_handler () () =
  Lwt.return (Foobar_container.page [
    div ~a:[a_id "foobar-forms"] [
      div ~a:[a_class ["left-bar"]] [
        p [
          pcdata "Enter your email to get an activation link to access to your account!";
        ];
        Foobar_view.forgot_password_form ();
      ];
    ]
  ])

let forgot_password_handler' () email =
  match_lwt Ebapp.User.uid_of_email email with
    | None ->
        Ebapp.Rmsg.Error.push (`User_does_not_exist email);
        Lwt.return ()
    | Some uid ->
        Ebapp.User.attach_activationkey
          ~email ~service:Foobar_services.main_service uid

let about_handler () () =
  Lwt.return (Foobar_container.page [
    div [
      p [
        pcdata "This template provides you a skeleton for an ocsigen application.";
      ];
      hr ();
      p [
        pcdata "Feel free to modify the code.";
      ];
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
  match_lwt Ebapp.User.verify_password login pwd with
    | Some uid -> Ebapp.Session.connect uid
    | None ->
        Ebapp.R.Error.push `Wrong_password;
        Lwt.return ()

let activation_handler akey () =
  (* SECURITY: we disconnect the user before doing anything
   * moreover in this case, if the user is already disconnect
   * we're going to disconnect him even if the actionvation key
   * is outdated. *)
  lwt () = Ebapp.Session.disconnect () in
  match_lwt User.uid_of_activationkey akey with
    | None ->
      (* Outdated activation key *)
      Ebapp.R.Error.push `Activation_key_outdated;
      Eliom_registration.Action.send ()
    | Some uid ->
      lwt () = Ebapp.Session.connect uid in
      Eliom_registration.Redirection.send Eliom_service.void_coservice'

          (*
let admin_service_handler uid gp pp =
  lwt user = Ebapp.User.user_of_uid uid in
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
    (Eba_services.connect_service)
    (connect_handler);

  Eliom_registration.Action.register
    (Eba_services.disconnect_service)
    (disconnect_handler);

  Eliom_registration.Any.register
    (Eba_services.activation_service)
    (activation_handler)
