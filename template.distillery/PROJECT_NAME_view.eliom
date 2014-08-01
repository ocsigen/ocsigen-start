{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

let generic_email_form ?label ~service () =
  D.post_form ~service
    (fun name ->
      let l = [
        string_input
          ~a:[a_placeholder "e-mail address"]
          ~input_type:`Email
          ~name
          ();
        string_input
          ~a:[a_class ["button"]]
          ~input_type:`Submit
          ~value:"Send"
          ();
      ]
      in
      match label with
        | None -> l
        | Some lab -> F.label [pcdata lab]::l) ()

let connect_form () =
  D.post_form ~service:%%%MODULE_NAME%%%_services.connect_service
    (fun (login, password) -> [
      string_input
        ~a:[a_placeholder "Your email"]
        ~name:login
        ~input_type:`Email
        ();
      string_input
        ~a:[a_placeholder "You password"]
        ~name:password
        ~input_type:`Password
        ();
      string_input
        ~a:[a_class ["button"]]
        ~input_type:`Submit
        ~value:"Sign in"
        ();
    ]) ()

let disconnect_button () =
  post_form ~service:%%%MODULE_NAME%%%_services.disconnect_service
    (fun _ -> [
      string_input
        ~a:[a_class ["button"]]
        ~input_type:`Submit
        ~value:"Logout"
        ();
    ]) ()

let sign_up_form () =
  generic_email_form ~service:%%%MODULE_NAME%%%_services.sign_up_service' ()

let forgot_password_form () =
  generic_email_form ~service:%%%MODULE_NAME%%%_services.forgot_password_service' ()

let information_form () =
  post_form
    ~a:[a_class ["info-form"]]
    ~service:%%%MODULE_NAME%%%_services.set_personal_data_service'
    (fun ((fname, lname), (password1, password2)) -> [
      string_input
        ~a:[a_placeholder "Your firstname"]
        ~name:fname
        ~input_type:`Text
        ();
      string_input
        ~a:[a_placeholder "Your lastname"]
        ~name:lname
        ~input_type:`Text
        ();
      string_input
        ~a:[a_placeholder "Your password"]
        ~name:password1
        ~input_type:`Password
        ();
      string_input
        ~a:[a_placeholder "Re-enter password"]
        ~name:password2
        ~input_type:`Password
        ();
      string_input
        ~a:[a_class ["button"]]
        ~input_type:`Submit
        ~value:"Submit"
        ();
    ]) ()

let preregister_form label =
  generic_email_form ~service:%%%MODULE_NAME%%%_services.preregister_service' ~label ()

let home_button () =
  form ~service:%%%MODULE_NAME%%%_services.main_service
    (fun _ -> [
      string_input
        ~input_type:`Submit
        ~value:"home"
        ();
    ])

let avatar user =
  img ~alt:"picture" ~a:[a_class ["%%%PROJECT_NAME%%%-avatar"]]
    ~src:(%%%MODULE_NAME%%%_user.avatar_uri_of_user user)
    ()

let username user =
  match %%%MODULE_NAME%%%_user.firstname_of_user user with
    | "" ->
      lwt email = %%%MODULE_NAME%%%_user.email_of_user user in
      Lwt.return (div [pcdata email])
    | s ->
      Lwt.return (div [pcdata s;
                       pcdata " ";
                       pcdata (%%%MODULE_NAME%%%_user.lastname_of_user user);
                      ])
