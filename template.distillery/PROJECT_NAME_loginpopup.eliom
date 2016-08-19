
let%shared connect_form () = Eliom_content.Html.D.(
  Form.post_form ~service:Os_services.connect_service
    (fun ((login, password), keepmeloggedin) -> [
      Form.input
        ~a:[a_placeholder "Your email"]
        ~name:login
        ~input_type:`Email
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
        ~a:[a_class ["button"]]
        ~input_type:`Submit
        ~value:"Sign in"
        Form.string;
    ]) ()
)

let%shared sign_up_form () =
  Os_view.generic_email_form ~service:Os_services.sign_up_service' ()

let%shared forgot_password_form () =
  Os_view.generic_email_form ~service:Os_services.forgot_password_service ()

let%shared forgotpwd_button () = Eliom_content.Html.D.(
  let popup_content = fun () -> Lwt.return @@
    div ~a:[a_class ["navbar-inverse";"eba-login-menu"]]
    [forgot_password_form ()] in
  let button_name = "forgot your password?" in
  Os_tools.popup_button
    ~button_name
    ~button_class:["button"]
    ~popup_content
)

let%shared sign_in_button () = Eliom_content.Html.D.(
  let popup_content = fun () -> Lwt.return @@
    div ~a:[a_class ["navbar-inverse";"eba-login-menu"]]
    [connect_form ()] in
  let button_name = "Sign In" in
  Os_tools.popup_button
    ~button_name
    ~button_class:["button"]
    ~popup_content
)

let%shared sign_up_button () = Eliom_content.Html.D.(
  let popup_content = fun () -> Lwt.return @@
    div ~a:[a_class ["navbar-inverse";"eba-login-menu"]]
    [sign_up_form ()] in
  let button_name = "Sign Up" in
  Os_tools.popup_button
    ~button_name
    ~button_class:["button"]
    ~popup_content
)
