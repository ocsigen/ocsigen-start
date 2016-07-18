
let%shared generic_email_form ~service = Eliom_content.Html.F.(
    Eliom_content.Html.D.Form.post_form ~xhr:false ~service
      (fun name ->
	[
          Form.input
            ~a:[a_placeholder "e-mail address"]
            ~input_type:`Email
            ~name
            Form.string;
	  hr ();
          Form.input
            ~a:[a_class ["button"]]
            ~input_type:`Submit
            ~value:"Send"
            Form.string;
	]
      ) ()
)

let%shared sign_up_form () =
  generic_email_form ~service:Eba_services.sign_up_service'

let%shared forgot_password_form () =
  generic_email_form ~service:Eba_services.forgot_password_service

let%shared forgotpwd_button () = Eliom_content.Html.D.(
  let popup_content = fun () -> Lwt.return @@
    div ~a:[a_class ["navbar-inverse";"eba_login_menu"]]
    [forgot_password_form ()] in
  let button_name = "forgot your password?" in
  Eba_tools.popup_button
    ~button_name
    ~button_class:["button"]
    ~popup_content
)

let%shared sign_in_button () = Eliom_content.Html.D.(
  let popup_content = fun () -> Lwt.return @@
    div ~a:[a_class ["navbar-inverse";"eba_login_menu"]]
    [Eba_view.connect_form ()] in
  let button_name = "Sign In" in
  Eba_tools.popup_button
    ~button_name
    ~button_class:["button"]
    ~popup_content
)

let%shared sign_up_button () = Eliom_content.Html.D.(
  let popup_content = fun () -> Lwt.return @@
    div ~a:[a_class ["navbar-inverse";"eba_login_menu"]]
    [sign_up_form ()] in
  let button_name = "Sign Up" in
  Eba_tools.popup_button
    ~button_name
    ~button_class:["button"]
    ~popup_content
)
