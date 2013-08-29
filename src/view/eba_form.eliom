{shared{
  open Eliom_content
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

let password_form_with_input () =
  let ri = ref None in
  let form =
    post_form
      ~service:Eba_services.set_password_service
      (fun (pwdn, pwd2n) ->
        let pass1 =
          D.string_input
            ~a:[a_required `Required;
                a_autocomplete `Off]
            ~input_type:`Password ~name:pwdn ()
        in
        let pass2 =
          D.string_input
            ~a:[a_required `Required;
                a_autocomplete `Off]
            ~input_type:`Password ~name:pwd2n ()
        in
        ri := Some pass1;
        ignore {unit{
          let pass1 = To_dom.of_input %pass1 in
          let pass2 = To_dom.of_input %pass2 in
          Lwt_js_events.async
            (fun () ->
               Lwt_js_events.inputs pass2
                 (fun _ _ ->
                    if (Js.to_string pass1##value <> Js.to_string pass2##value)
                    then (Js.Unsafe.coerce pass2)##setCustomValidity("Passwords do not match")
                    else (Js.Unsafe.coerce pass2)##setCustomValidity("");
                    Lwt.return ()))
        }};
        [
          table
            (tr [td [label [pcdata "Password:"]]; td [pass1]])
            [
              tr [td [label [pcdata "Retype password:"]]; td [pass2]];
            ];
          string_input ~input_type:`Submit ~value:"Send" ()
        ])
      ()
  in
  form, match !ri with Some inp -> inp | None -> failwith "should_never_happen"

let password_form () =
  let (form,_) = password_form_with_input () in form

let personal_info_form_with_input
      ?(firstname = "")
      ?(lastname = "")
      ?(password1 = "")
      ?(password2 = "")
      ()
  =
  let ri = ref None in
  let form =
    post_form
      ~a:[a_id "eba_personal_info_form"]
      ~service:Eba_services.set_personal_data_service
      (fun ((fnn, lnn), (pwdn, pwd2n)) ->
         let pass1 =
           D.string_input
             ~a:[a_required `Required;
                 a_autocomplete `Off]
             ~input_type:`Password ~name:pwdn ~value:password1 ()
         in
         let pass2 =
           D.string_input
             ~a:[a_required `Required;
                 a_autocomplete `Off]
             ~input_type:`Password ~name:pwd2n ~value:password2 ()
         in
         ri := Some pass1;
         ignore {unit{
           let pass1 = To_dom.of_input %pass1 in
           let pass2 = To_dom.of_input %pass2 in
           Lwt_js_events.async
             (fun () ->
                Lwt_js_events.inputs pass2
                  (fun _ _ ->
                     if (Js.to_string pass1##value <> Js.to_string pass2##value)
                     then (Js.Unsafe.coerce pass2)##setCustomValidity("Passwords do not match")
                     else (Js.Unsafe.coerce pass2)##setCustomValidity("");
                     Lwt.return ()))
         }};
         [
           table
             (tr [td [label [pcdata "Firstname:"]];
                  td [string_input
                        ~a:[a_required `Required]
                        ~input_type:`Text ~name:fnn ~value:firstname ()]])
             [
               tr [td [label [pcdata "Lastname:"]];
                   td [string_input
                         ~a:[a_required `Required]
                         ~input_type:`Text ~name:lnn ~value:lastname ()]];
               tr [td [label [pcdata "Password:"]]; td [pass1]];
               tr [td [label [pcdata "Retype password:"]]; td [pass2]];
             ];
           string_input ~input_type:`Submit ~value:"Send" ()
         ])
      ()
  in
  form, match !ri with Some inp -> inp | None -> failwith "should_never_happen"

let personal_info_form ?firstname ?lastname ?password1 ?password2 () =
  let (form,_) =
    personal_info_form_with_input
      ?firstname
      ?lastname
      ?password1
      ?password2
      ()
  in
  form

let login_form_with_input ?(login = "") () =
  let ri = ref None in
  let form =
    D.post_form
    ~a:[a_id "eba_connectionbox"]
    ~service:Eba_services.login_service
    (fun (loginname, pwdname) ->
      let inp =
        D.string_input
          ~a:[a_placeholder "e-mail address"]
          ~input_type:`Email ~name:loginname ~value:login  ()
      in
      ri := Some inp;
      [
        inp;
        string_input
          ~a:[a_placeholder "password"]
          ~input_type:`Password ~name:pwdname ();
        string_input
          ~input_type:`Submit ~value:"connect" ();
      ])
    ()
  in
  form, match !ri with Some inp -> inp | None -> failwith "should_never_happen"

let login_form ?login () =
  let (form,_) = login_form_with_input ?login () in form

let generic_email_form_with_input
      ?(login = "")
      ?(id = "eba_email_form")
      ~service
      text
  =
  let ri = ref None in
  let form =
    D.post_form
    ~a:[a_id id;
        a_style "display: none"]
    ~service
    (fun fieldname ->
      let inp =
        D.string_input
          ~a:[a_placeholder "e-mail address"]
          ~input_type:`Email ~name:fieldname ~value:login ()
      in
      ri := Some inp;
      [
        label [pcdata text];
        inp;
        string_input
          ~input_type:`Submit ~value:"confirm" ();
      ])
    ()
  in
  form, match !ri with Some inp -> inp | None -> failwith "should_never_happen"

let lost_password_form_with_input ?login () =
  generic_email_form_with_input
    ?login ~id:"eba_activationemail"
    ~service:Eba_services.lost_password_service
    "Enter your e-mail address to receive an activation link"

let lost_password_form ?login () =
  let (form,_) = lost_password_form_with_input ?login () in form

let sign_up_form_with_input ?login () =
  generic_email_form_with_input
    ?login ~id:"eba_activationemail"
    ~service:Eba_services.sign_up_service
    "Enter your e-mail address to receive an activation link"

let sign_up_form ?login () =
  let (form,_) = sign_up_form_with_input ?login () in form
