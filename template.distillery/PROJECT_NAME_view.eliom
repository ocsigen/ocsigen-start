{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

let connect_form () =
  post_form ~service:%%%MODULE_NAME%%%_services.connect_service
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
  post_form ~service:%%%MODULE_NAME%%%_services.sign_up_service'
    (fun (email) -> [
      string_input
        ~a:[a_placeholder "Your email"]
        ~name:email
        ~input_type:`Email
        ();
      string_input
        ~a:[a_class ["button"]]
        ~input_type:`Submit
        ~value:"Sign up"
        ();
    ]) ()

let forgot_password_form () =
  post_form ~service:%%%MODULE_NAME%%%_services.forgot_password_service'
    (fun (email) -> [
      string_input
        ~a:[a_placeholder "Your email"]
        ~name:email
        ~input_type:`Email
        ();
      string_input
        ~a:[a_class ["button"]]
        ~input_type:`Submit
        ~value:"Go"
        ();
    ]) ()

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

let preregister_form () =
  post_form ~service:%%%MODULE_NAME%%%_services.preregister_service'
    (fun email -> [
      string_input
        ~a:[a_placeholder "Your email"]
        ~name:email
        ~input_type:`Email
        ();
      string_input
        ~a:[a_class ["button"]]
        ~input_type:`Submit
        ~value:"Submit"
        ();
    ]) ()

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
      Lwt.return (span [pcdata email])
    | s ->
      Lwt.return (span [pcdata s;
                        pcdata " ";
                        pcdata (%%%MODULE_NAME%%%_user.lastname_of_user user);
                       ])
