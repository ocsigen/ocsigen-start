
let%server connected_welcome_box () = Eliom_content.Html.F.(
  let info, ((fn, ln), (p1, p2)) =
    match Eliom_reference.Volatile.get Eba_msg.wrong_pdata with
    | None ->
      p [
        pcdata "Your personal information has not been set yet.";
        br ();
        pcdata "Please take time to enter your name and to set a password."
      ], (("", ""), ("", ""))
    | Some wpd -> p [pcdata "Wrong data. Please fix."], wpd
  in
  div ~a:[a_class ["eba_login_menu";"eba_welcome_box"]] [
    div [h2 [pcdata ("Welcome!")]; info];
    Eba_view.information_form
      ~firstname:fn ~lastname:ln
      ~password1:p1 ~password2:p2
      ()
  ]
)

