
let%shared connected_user_box user service = Eliom_content.Html.D.(
  let username = Eba_view.username user in
  div ~a:[a_class ["connected_user_box"]] [
    Eba_view.avatar user;
    div [username;
	 %%%MODULE_NAME%%%_usermenu.user_menu user service]
  ]
)

let%shared connection_box () = Eliom_content.Html.D.(
  let%lwt sign_in    = %%%MODULE_NAME%%%_loginpopup.sign_in_button () in
  let%lwt sign_up    = %%%MODULE_NAME%%%_loginpopup.sign_up_button () in
  let%lwt forgot_pwd = %%%MODULE_NAME%%%_loginpopup.forgotpwd_button () in
  Lwt.return @@ div ~a:[a_class ["eba_login_menu"]] [
    sign_in;
    sign_up;
    forgot_pwd
  ]
)

let%shared userbox user service = Eliom_content.Html.F.(
  let d = div ~a:[a_class ["navbar-right"]] in
  match user with
  | None ->
    let%lwt cb = connection_box () in
    Lwt.return @@ d [cb]
  | Some user ->
    Lwt.return @@ d [connected_user_box user service]
)
