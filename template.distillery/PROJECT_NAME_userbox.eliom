
let msg () = Eba_userbox.(
  let activation_key_created =
    Eliom_reference.Volatile.get Eba_msg.activation_key_created in
  let wrong_password =
    Eliom_reference.Volatile.get wrong_password in
  let user_already_exists =
    Eliom_reference.Volatile.get user_already_exists in
  let user_does_not_exist =
    Eliom_reference.Volatile.get user_does_not_exist in
  let user_already_preregistered =
    Eliom_reference.Volatile.get user_already_preregistered in
  let activation_key_outdated =
    Eliom_reference.Volatile.get activation_key_outdated in
  if activation_key_created
  then Some "An email has been sent to this address. Click on the link it contains to log in."
  else if wrong_password
  then Some "Wrong password"
  else if activation_key_outdated
  then Some "Invalid activation key, ask for a new one."
  else if user_already_exists
  then Some "E-mail already exists"
  else if user_does_not_exist
  then Some "User does not exist"
  else if user_already_preregistered
  then Some "E-mail already preregistered"
  else None
)

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

let%server userbox user service = Eliom_content.Html.F.(
  let d = div ~a:[a_class ["navbar-right"]] in
  match user with
  | None ->
    begin match msg () with
    | None ->
      let%lwt cb = connection_box () in
      Lwt.return @@ d [cb]
    | Some msg ->
      let msg = p [pcdata msg] in
      let%lwt cb = connection_box () in
      Lwt.return @@ d [msg; cb]
    end 
  | Some user ->
    Lwt.return @@ d [connected_user_box user service]
)

let%client userbox user service = Eliom_content.Html.F.(
  let d = div ~a:[a_class ["navbar-right"]] in
  match user with
  | None ->
    let%lwt cb = connection_box () in
    Lwt.return @@ d [cb]
  | Some user ->
    Lwt.return @@ d [connected_user_box user service]
)
