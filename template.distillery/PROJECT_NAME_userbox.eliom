
let%shared connected_user_box user service = Eliom_content.Html.D.(
  let username = Eba_view.username user in
  div ~a:[a_class ["connected_user_box"]] [
    Eba_view.avatar user;
    div [username;
	 %%%MODULE_NAME%%%_usermenu.user_menu user service]
  ]
)

let%shared connection_box () = Eliom_content.Html.D.(
  let but = div ~a:[a_class ["eba_login_button"]]
    [pcdata "Login"]
  in
  let menu = div ~a:[a_class ["usermenu_pop";"navbar-inverse"]] [] in
  let%lwt connectbox =
    Eba_userbox.userbox None
      %%%MODULE_NAME%%%_services.upload_user_avatar_service in
  ignore
    (Ow_button.button_dyn_alert but menu
       [%client (fun _ _ ->
         let close () =
           let o = Ow_button.to_button_dyn_alert ~%but in
           o##unpress
         in
         Lwt.return ([~%connectbox]): 'a -> 'b)]);
  div ~a:[a_class ["eba_login_menu"]] [but; menu] |> Lwt.return
)

let%shared userbox user service = Eliom_content.Html.F.(
  let%lwt userbox =
    Eba_userbox.userbox user
      %%%MODULE_NAME%%%_services.upload_user_avatar_service in
  (match user with
  | None ->
    div ~a:[a_class ["navbar-right";"collapse";"eba_login_menu"]]
      [userbox]
  | Some user ->
    div ~a:[a_class ["navbar-right"]]
      [connected_user_box user service]
  ) |> Lwt.return
)
