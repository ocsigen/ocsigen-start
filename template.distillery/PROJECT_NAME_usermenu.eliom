
let%shared user_menu close user service = Eliom_content.Html.D.(
  [
    p [pcdata "Change your password:"];
    Eba_view.password_form ~service:Eba_services.set_password_service' ();
    hr ();
    Eba_userbox.upload_pic_link close service (Eba_user.userid_of_user user);
    hr ();
    Eba_userbox.reset_tips_link close;
    hr ();
    Eba_view.disconnect_button ();
  ]
)

let%shared user_menu user service = Eliom_content.Html.D.(
  let but = div ~a:[a_class ["btn";"eba_usermenu_button"]]
    [pcdata "Menu"]
  in
  let menu = div ~a:[a_class ["navbar-inverse";"usermenu_pop"]] [] in
  ignore
    (Ow_button.button_dyn_alert but menu
       [%client (fun _ _ ->
         let close () =
           let o = Ow_button.to_button_dyn_alert ~%but in
           o##unpress
         in
         Lwt.return (user_menu close ~%user ~%service): 'a -> 'b)]);
  div ~a:[a_class ["eba_usermenu"]] [but; menu]
)
