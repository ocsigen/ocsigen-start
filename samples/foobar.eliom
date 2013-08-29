{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

(* The following codes could be use as a distillery's template. It defines
 * a basic user interface using EBA.
 *
 * Many parts could be modify to make your website more personnal. Feel free
 * to remove or add code into these ones.
 * *)

let print_user_box u =
  let print_user_avatar u =
    let uavatar =
      D.div ~a:[a_class ["eba_upload_pic"]]
        [pcdata "Upload picture"]
    in
    Ebapp.View.Image.start_crop_on_clicking_on uavatar u;
    uavatar
    (*
    D.img
      ~a:[a_class ["eba_avatar_button"]]
      ~alt:(Ebapp.U.firstname_of_user u)
      ~src:(Ebapp.U.make_avatar_uri (Ebapp.U.avatar_of_user u))
      ()
     *)
  in
  let print_user_name u =
    D.span ~a:[a_class ["eba_username"]] [pcdata (Ebapp.U.fullname_of_user u)]
  in
  let print_user_settings u =
    let but =
      D.span ~a:[a_class ["eba_settings_button"]]
        [i ~a:[a_class ["icon-gear";"icon-large"]] []]
    in
    let password_form = Ebapp.Default.password_form () in
    ignore {unit{
      Eba_view.H.box_on_click ~set:Eba_view.global_set (%but)
        (fun () ->
           let log_but =
             D.span ~a:[a_class ["eba_logout_button"]]
               [i ~a:[a_class ["icon-signout"]] []]
           in
           Eba_view.H.on_click (log_but)
             (fun () ->
                Eliom_client.change_page %Ebapp.Sv.logout_service () ());
           Lwt.return [
             log_but;
             %password_form;
             F.a ~service:%Ebapp.Sv.admin_service [pcdata "admin page"] ();
           ])
    }};
    but
  in
  D.div ~a:[a_class ["eba_user_box"]]
    [
      print_user_avatar u;
      print_user_name u;
      print_user_settings u;
    ]

let disconnected_home_page () =
  let id = "eba_login_signup_box" in
  if Ebapp.Rmsg.Notice.has ((=) `Activation_key_created)
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
    let form1, i1 = Ebapp.Default.login_form_with_input () in
    let o1 = {(Ew_button.show_hide_t){
      new Ew_button.show_hide
        ~pressed:true
        ~set:%set ~button:%button1
        ~closeable_by_button:false
        %form1
    }}
    in
    let button2 = D.h2 [pcdata "Lost password"] in
    let form2, i2 = Ebapp.Default.lost_password_form_with_input () in
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
    let form4, i4 = Ebapp.Default.sign_up_form_with_input () in
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
        let msg = To_dom.of_p (p ~a:[a_class ["eba_error"]] [pcdata %msg]) in
          ignore ((%o)#press);
          Dom.appendChild d msg;
          ignore
            (lwt () = Lwt_js.sleep 2. in
             Dom.removeChild d msg;
             Lwt.return ())
      }};
      Lwt.return ()
    in
    lwt state = Ebapp.St.get_website_state () in
    (* here we will return the div correponding to the current
     * website state, and also a function to handle specific
     * flash messages *)
    let d, handle_rmsg =
      match state with
        | `Restricted ->
        (*| (Ebapp.State.restricted_state) ->*)
           (D.div ~a:[a_id id]
                          [button1; (*button3;*) form1; (*form3*)]),
           (* this function will handle only flash message error associated
            * to this website mode *)
           (fun d rmsg ->
              print_endline "rmsg";
              match rmsg with
                (* Login error *)
                | `Wrong_password ->
                    (press o1 d "Wrong password")
                (* Preregister error *)
                (*
                | Eba_fm.User_already_preregistered _ ->
                    (press o3 d "This email is not available")
                *)
                | `Activation_key_outdated ->
                    (press o2 d "Invalid activation key, ask for a new one.")
                | _ ->
                    (* default case: SHOULD NEVER HAPPEN !*)
                    (press o1 d "Something went wrong"))
        | `Normal ->
           (D.div ~a:[a_id id]
                          [button1; button2; button4; form1; form2; form4]),
           (* this function will handle only flash message error associated
            * to this website mode *)
           (fun d rmsg ->
              print_endline "rmsg";
              match rmsg with
                (* Login error *)
                | `Wrong_password ->
                    (press o1 d "Wrong password")
                (* Register error *)
                | `User_already_exists _ ->
                    (press o4 d "This user already exists")
                (* Lost password error *)
                | `User_does_not_exist _ ->
                    (press o2 d "This user does not exist")
                | `Activation_key_outdated ->
                    (press o2 d "Invalid activation key, ask for a new one.")
                | _ ->
                    (* default case: SHOULD NEVER HAPPEN !*)
                    (press o1 d "Something went wrong"))
    in
    (* handle_rmsg : currify *)
      print_endline "foobar";
    lwt () = (Ebapp.R.Error.iter (handle_rmsg d)) in
    Lwt.return d

let connected_welcome_box () =
  lwt info, ((fn,ln),(p1,p2)) =
    try
      let wpd =
        Ebapp.R.Error.get
          (function
             | `Wrong_personal_data wpd -> Some wpd
             | _ -> None)
      in
      Lwt.return (p [pcdata "Wrong data. Please fix."], wpd)
    with Not_found ->
      Lwt.return
        (p [
          pcdata "Your personal information has not been set yet.";
          br ();
          pcdata "Please take time to enter your name and to set a password."
        ], (("", ""), ("", "")))
  in
  Lwt.return
    (div ~a:[a_id "eba_welcome_box"]
       [
         h2 [pcdata ("Welcome to "^Ebapp.App.app_name)];
         info;
         Ebapp.Default.personal_info_form
           ~firstname:fn ~lastname:ln
           ~password1:p1 ~password2:p2
           ()
       ])

let main_service_handler uid () () =
  lwt user = Ebapp.User.user_of_uid uid in
  let title =
    Eliom_content.Html5.Id.create_global_elt
      (D.h1 [
        a ~service:Eba_services.main_service
          [pcdata Ebapp.App.app_name] ()
      ])
  in
  lwt page_content =
    if Ebapp.U.is_new user
    then
      (lwt wb = connected_welcome_box () in
       Lwt.return
         [
           wb;
         ])
    else Lwt.return []
  in
  lwt st = Ebapp.St.get_website_state () in
  let st = Ebapp.St.name_of_state st in
  let navbar =
    D.div ~a:[a_class ["eba_navbar"]]
      [
        title;
        D.div ~a:[a_class ["eba_navbar_inner"]]
          [
            p [pcdata st]
          ];
        print_user_box user
      ]
  in
  Lwt.return
    (navbar::page_content)

let _ =
  let fallback gp pp =
    lwt lb = disconnected_home_page () in
    (*let lb = Ebapp.V.Form.login_form () in*)
    Lwt.return
      [
        D.div ~a:[a_class ["eba_welcomepage"]]
          [
            lb
          ]
      ]
  in
  Ebapp.App.register
    (Ebapp.Sv.main_service)
    (Ebapp.P.connected_page ~fallback main_service_handler)
