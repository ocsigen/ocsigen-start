(* Copyright Vincent Balat, Séverine Maingaud, Charly Chevalier *)

module Eba_fm = Eba_flash_message

{shared{
  open Eliom_content
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

{server{

let login_signin_box () =
  let id = "ol_login_signup_box" in
  if Eliom_reference.Volatile.get Eba_session.activationkey_created
  then
    Lwt.return
      (D.div ~a:[a_id id]
         [p [pcdata "An email has been sent to this address.";
             br();
             pcdata "Click on the link it contains to log in."]])
  else
    let set = {(Ew_button.radio_set_t){
      Ew_button.new_radio_set ()
    }} in
    let button1 = D.h2 [pcdata "Login"] in
    let form1, i1 = Eba_form.login_form_with_input () in
    let o1 = {(Ew_button.show_hide_t){
      new Ew_button.show_hide
        ~pressed:true
        ~set:%set ~button:%button1
        ~closeable_by_button:false
        %form1
    }}
    in
    let button2 = D.h2 [pcdata "Lost password"] in
    let form2, i2 = Eba_form.lost_password_form_with_input () in
    let o2 = {(Ew_button.show_hide_t){
      new Ew_button.show_hide
        ~set:%set ~button:%button2
        ~closeable_by_button:false
        %form2
    }}
    in
      (*
    let button3 = D.h2 [pcdata "Preregister"] in
    let form3, i3 = Eba_preregister.preregister_box preregister_service in
    let o3 = {(Ew_button.show_hide_t){
      new show_hide_focus
        ~set:%set ~button:(To_dom.of_h2 %button3)
        ~closeable_by_button:false
        ~focused:(To_dom.of_input %i3) (To_dom.of_form %form3)
    }}
    in
       *)
    let button4 = D.h2 [pcdata "Register"] in
    let form4, i4 = Eba_form.sign_up_form_with_input () in
    let o4 = {(Ew_button.show_hide_t){
      new Ew_button.show_hide
        ~set:%set ~button:%button4
        ~closeable_by_button:false
        %form4
    }}
    in
    (* function to press the corresponding button and display
     * the flash message error.
     * [d] is currently an server value, so we need to use % *)
    let press o d msg =
      ignore {unit{
        let d = To_dom.of_div %d in
        let msg = To_dom.of_p (p ~a:[a_class ["ol_error"]] [pcdata %msg]) in
          ignore ((%o)#press);
          Dom.appendChild d msg;
          ignore
            (lwt () = Lwt_js.sleep 2. in
             Dom.removeChild d msg;
             Lwt.return ())
      }}
    in
    lwt state = Eba_site.get_state () in
    (* here we will return the div correponding to the current
     * website state, and also a function to handle specific
     * flash messages *)
    let d, handle_flash =
      match state with
        | Eba_site.Close ->
           (D.div ~a:[a_id id]
                          [button1; (*button3;*) form1; (*form3*)]),
           (* this function will handle only flash message error associated
            * to this website mode *)
           (fun flash d ->
              match flash with
                (* Login error *)
                | Eba_fm.Wrong_password ->
                    (press o1 d "Wrong password")
                (* Preregister error *)
                (*
                | Eba_fm.User_already_preregistered _ ->
                    (press o3 d "This email is not available")
                *)
                | Eba_fm.Activation_key_outdated ->
                    (press o2 d "Invalid activation key, ask for a new one.")
                | _ ->
                    (* default case: SHOULD NEVER HAPPEN !*)
                    (press o1 d "Something went wrong"))
        | Eba_site.Open ->
           (D.div ~a:[a_id id]
                          [button1; button2; button4; form1; form2; form4]),
           (* this function will handle only flash message error associated
            * to this website mode *)
           (fun flash d ->
              match flash with
                (* Login error *)
                | Eba_fm.Wrong_password ->
                    (press o1 d "Wrong password")
                (* Register error *)
                | Eba_fm.User_already_exists _ ->
                    (press o4 d "This user already exists")
                (* Lost password error *)
                | Eba_fm.User_does_not_exist _ ->
                    (press o2 d "This user does not exist")
                | Eba_fm.Activation_key_outdated ->
                    (press o2 d "Invalid activation key, ask for a new one.")
                | _ ->
                    (* default case: SHOULD NEVER HAPPEN !*)
                    (press o1 d "Something went wrong"))
    in
    lwt has_flash = Eba_fm.has_flash_msg () in
    lwt () =
      if has_flash
      then begin
        lwt flash = (Eba_fm.get_flash_msg ()) in
        let () = handle_flash flash d in
        Lwt.return ()
      end
      else Lwt.return ()
    in
    Lwt.return d
}}

let welcome_box () =
  let info, ((fn,ln),(p1,p2)) =
    (match Eliom_reference.Volatile.get Eba_session.wrong_perso_data with
      | None ->
        (p [pcdata "Your personal information has not been set yet.";
            br ();
            pcdata "Please take time to enter your name and to set a password."]
           , (("", ""), ("", "")))
      | Some wpd ->
        (p [pcdata "Wrong data. Please fix."], wpd)
    )
  in
  div ~a:[a_id "ol_welcome_box"]
    [
      div [
        h2 [pcdata "Welcome to myproject"];
        info
      ];
      Eba_form.personal_info_form ~firstname:fn ~lastname:ln ~password1:p1 ~password2:p2 ()
    ]
