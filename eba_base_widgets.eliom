(* Copyright Vincent Balat, Séverine Maingaud *)

(** This module defines generic widgets used by Myproject
    (but not generic enough to be in the widget library)
*)


{shared{
open Eliom_content
open Eliom_content.Html5
open Eliom_content.Html5.F

let (>>=) = Lwt.bind
let (>|=) = Lwt.(>|=)
}}

(********************************************)
(** Small widgets *)


{server{

module Eba_fm = Eba_flash_message

(** Login box *)

let connection_box service =
  let r = ref None in
  let f = D.post_form
    ~a:[a_id "ol_connectionbox"]
    ~service
    (fun (loginname, pwdname) ->
      let i = D.string_input
        ~a:[a_placeholder "e-mail address"]
        ~input_type:`Email ~name:loginname ()
      in
      r := Some i;
      [i;
       string_input
         ~a:[a_placeholder "password"]
         ~input_type:`Password ~name:pwdname ();
       string_input
         ~input_type:`Submit ~value:"connect" ();
      ])
    ()
  in
  f, match !r with Some i -> i | None -> failwith "connection_box"

let email_box service =
  let r = ref None in
  let f = D.post_form
    ~a:[a_id "ol_activationemail";
        a_style "display: none"]
    ~service
    (fun fieldname ->
      let i = D.string_input
         ~a:[a_placeholder "e-mail address"]
         ~input_type:`Email ~name:fieldname ()
      in
      r := Some i;
      [label [pcdata "Enter your e-mail address to receive an activation link"];
       i;
       string_input
         ~input_type:`Submit ~value:"confirm" ();
      ])
    ()
  in
  f, match !r with Some i -> i | None -> failwith "email_box"

 }}

{shared{
type restr_show_hide_focus =
  < press : unit Lwt.t;
    unpress : unit Lwt.t;
    on_press : unit Lwt.t;
    on_unpress : unit Lwt.t;
    on_pre_press : unit Lwt.t;
    on_pre_unpress : unit Lwt.t;
    on_post_press : unit Lwt.t;
    on_post_unpress : unit Lwt.t;
    switch: unit Lwt.t;
    pressed: bool;
    >
}}

{server{

let login_signin_box
      connection_service
      lost_password_service
      sign_up_service
      preregister_service
      ()
      =
  let id = "ol_login_signup_box" in
  if Eliom_reference.Volatile.get Eba_sessions.activationkey_created
  then
    Lwt.return
      (D.div ~a:[a_id id]
         [p [pcdata "An email has been sent to this address.";
             br();
             pcdata "Click on the link it contains to log in."]])
  else
    let set = {(Eliom_widgets.Button.radio_set_t){
      Eliom_widgets.Button.new_radio_set ()
    }} in
    let button1 = D.h2 [pcdata "Login"] in
    let form1, i1 = connection_box connection_service in
    let o1 = {restr_show_hide_focus{
      new Eliom_widgets.Button.button_show_hide
        ~pressed:true
        ~set:%set ~button:%button1
        ~button_closeable:false
        %form1
    }}
    in
    let button2 = D.h2 [pcdata "Lost password"] in
    let form2, i2 = email_box lost_password_service in
    let o2 = {restr_show_hide_focus{
      new Eliom_widgets.Button.button_show_hide
        ~set:%set ~button:%button2
        ~button_closeable:false
        %form2
    }}
    in
      (*
    let button3 = D.h2 [pcdata "Preregister"] in
    let form3, i3 = Eba_preregister.preregister_box preregister_service in
    let o3 = {restr_show_hide_focus{
      new show_hide_focus
        ~set:%set ~button:(To_dom.of_h2 %button3)
        ~button_closeable:false
        ~focused:(To_dom.of_input %i3) (To_dom.of_form %form3)
    }}
    in
       *)
    let button4 = D.h2 [pcdata "Register"] in
    let form4, i4 = email_box sign_up_service in
    let o4 = {restr_show_hide_focus{
      new Eliom_widgets.Button.button_show_hide
        ~set:%set ~button:%button4
        ~button_closeable:false
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

let login_signin_box =
  login_signin_box
    Eba_services.login_service
    Eba_services.lost_password_service
    Eba_services.sign_up_service
    Eba_services.preregister_service

let personal_info_form ((fn, ln), (p1, p2)) =
  post_form
    ~a:[a_id "ol_personal_info_form"]
    ~service:Eba_services.set_personal_data_service
    (fun ((fnn, lnn), (pwdn, pwd2n)) ->
      let pass1 =
        D.string_input
          ~a:[a_required `Required;
              a_autocomplete `Off]
          ~input_type:`Password ~name:pwdn ~value:p1 ()
      in
      let pass2 =
        D.string_input
          ~a:[a_required `Required;
              a_autocomplete `Off]
          ~input_type:`Password ~name:pwd2n ~value:p2 ()
      in
      ignore {unit{
        let pass1 = To_dom.of_input %pass1 in
        let pass2 = To_dom.of_input %pass2 in
        Lwt_js_events.(async (fun () ->
          inputs pass2 (fun _ _ ->
            if (Js.to_string pass1##value <> Js.to_string pass2##value)
            then (Js.Unsafe.coerce pass2)##setCustomValidity("Passwords do not match")
            else (Js.Unsafe.coerce pass2)##setCustomValidity("");
            Lwt.return ())))
      }};
      [table
          (tr [td [label [pcdata "Firstname:"]];
               td [string_input
                      ~a:[a_required `Required]
                      ~input_type:`Text ~name:fnn ~value:fn ()]])
          [tr [td [label [pcdata "Lastname:"]];
               td [string_input
                      ~a:[a_required `Required]
                      ~input_type:`Text ~name:lnn ~value:ln ()]];
           tr [td [label [pcdata "Password:"]]; td [pass1]];
           tr [td [label [pcdata "Retype password:"]]; td [pass2]];
          ];
       string_input ~input_type:`Submit ~value:"Send" ()
      ])
    ()

}}

let welcome_box () =
  let info, default_data =
    (match Eliom_reference.Volatile.get Eba_sessions.wrong_perso_data with
      | None ->
        (p [pcdata "Your personal information has not been set yet.";
            br ();
            pcdata "Please take time to enter your name and to set a password."]
           , (("", ""), ("", "")))
      | Some wpd ->
        (p [pcdata "Wrong data. Please fix."], wpd)
    )
  in
  div
    ~a:[a_id "ol_welcome_box"]
    [div [h2 [pcdata "Welcome to myproject"];
          info];
     personal_info_form default_data]
