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
         ~a:[a_placeholder "Password"]
         ~input_type:`Password ~name:pwdname ();
       string_input
         ~input_type:`Submit ~value:"Connect" ();
      ])
    ()
  in
  f, match !r with Some i -> i | None -> failwith "connection_box"

let email_form service =
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
       i])
    ()
  in
  f, match !r with Some i -> i | None -> failwith "connection_box"

 }}

{client{

class ['a] show_hide_focus ?pressed ?button ?set
  ?method_closeable ?button_closeable ?focused elt =
object
  inherit ['a] Ew_buh.show_hide ?pressed ?button ?set
    ?method_closeable ?button_closeable elt as papa
  method post_press =
    lwt () = papa#post_press in
    (match focused with None -> () | Some e -> e##focus());
    Lwt.return ()
end

}}

{shared{
type restr_show_hide_focus =
  < press : unit Lwt.t;
    unpress : unit Lwt.t;
    pre_press : unit Lwt.t;
    pre_unpress : unit Lwt.t;
    post_press : unit Lwt.t;
    post_unpress : unit Lwt.t;
    press_action: unit Lwt.t;
    unpress_action: unit Lwt.t;
    switch: unit Lwt.t;
    pressed: bool;
    >
}}

{server{
let login_signin_box ~wrong_pwd ~invalid_actkey
    connection_service activation_email_service =
  let id = "ol_login_signup_box" in
  if Eliom_reference.Volatile.get Ol_sessions.activationkey_created
  then D.div ~a:[a_id id]
    [p [pcdata "An email has been sent to this address.";
        br();
        pcdata "Click on the link it contains to log in."]]
  else
    let button1 = D.h2 [pcdata "Login"] in
    let form1, i1 = connection_box connection_service in
    let button2 = D.h2 [pcdata "Sign up / Lost password"] in
    let form2, i2 = email_form activation_email_service in
    let set = {Ew_buh.radio_set{Ew_buh.new_radio_set ()}} in
    let o2 = {restr_show_hide_focus{
      let set = %set in
      ignore
        (new show_hide_focus
           ~pressed:true
           ~set ~button:(To_dom.of_h2 %button1)
           ~button_closeable:false
           ~focused:(To_dom.of_input %i1) (To_dom.of_form %form1));
      (To_dom.of_input %i1)##focus();
      new show_hide_focus
        ~set ~button:(To_dom.of_h2 %button2)
        ~button_closeable:false
        ~focused:(To_dom.of_input %i2) (To_dom.of_form %form2);
    }}
    in
    let d = D.div ~a:[a_id id] [button1; button2; form1; form2] in
    if wrong_pwd || invalid_actkey
    then begin
      let msg = if wrong_pwd then "Wrong password"
        else "Invalid activation key. Ask for a new one."
      in
      ignore
        {unit{ let d = To_dom.of_div %d in
               let msg = To_dom.of_p
                 (p ~a:[a_class ["ol_error"]] [pcdata %msg])
               in
               Dom.appendChild d msg;
               ignore (lwt () = Lwt_js.sleep 2. in
                       Dom.removeChild d msg;
                       if %invalid_actkey
                       then (%o2)#press
                       else Lwt.return ())
        }}
    end;
    d

let personal_info_form ((fn, ln), (p1, p2)) =
  post_form
    ~a:[a_id "ol_personal_info_form"]
    ~service:Ol_services.set_personal_data_service
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
    (match Eliom_reference.Volatile.get Ol_sessions.wrong_perso_data with
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
