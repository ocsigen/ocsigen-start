(* Copyright University paris Diderot *)
(* Do not hesitate to copy paste part of this code, modify it,
   and integrate it in your app to customize the behaviour according to
   your needs. *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F

let generic_email_form ?a ?label ?(text="Send") ~service () =
  D.post_form ?a ~service
    (fun name ->
      let l = [
        string_input
          ~a:[a_placeholder "e-mail address"]
          ~input_type:`Email
          ~name
          ();
        string_input
          ~a:[a_class ["button"]]
          ~input_type:`Submit
          ~value:text
          ();
      ]
      in
      match label with
        | None -> l
        | Some lab -> F.label [pcdata lab]::l) ()

let connect_form ?a () =
  D.post_form ?a ~xhr:false ~service:%Eba_services.connect_service
    (fun (login, password) -> [
      string_input
        ~a:[a_placeholder "Your email"]
        ~name:login
        ~input_type:`Email
        ();
      string_input
        ~a:[a_placeholder "Your password"]
        ~name:password
        ~input_type:`Password
        ();
      string_input
        ~a:[a_class ["button"]]
        ~input_type:`Submit
        ~value:"Sign in"
        ();
    ]) ()

}}

{shared{
let disconnect_button ?a () =
  post_form ?a ~service:%Eba_services.disconnect_service
    (fun _ -> [
         button ~button_type:`Submit
           [Ow_icons.F.signout (); pcdata "Logout"]
       ]) ()

let sign_up_form ?a () =
  generic_email_form ?a ~service:%Eba_services.sign_up_service' ()

let forgot_password_form ?a () =
  generic_email_form ?a
    ~service:%Eba_services.forgot_password_service ()

let information_form ?a
    ?(firstname="") ?(lastname="") ?(password1="") ?(password2="")
    () =
  D.post_form ?a ~service:%Eba_services.set_personal_data_service'
    (fun ((fname, lname), (passwordn1, passwordn2)) ->
       let pass1 = D.string_input
           ~a:[a_placeholder "Your password"]
           ~name:passwordn1
           ~value:password1
           ~input_type:`Password
           ()
       in
       let pass2 = D.string_input
           ~a:[a_placeholder "Re-enter password"]
           ~name:passwordn2
           ~value:password2
           ~input_type:`Password
           ()
       in
       let _ = {unit{
         let pass1 = To_dom.of_input %pass1 in
         let pass2 = To_dom.of_input %pass2 in
         Lwt_js_events.(async (fun () ->
           inputs pass2 (fun _ _ ->
             if (Js.to_string pass1##value <> Js.to_string pass2##value)
             then (Js.Unsafe.coerce pass2)##setCustomValidity
                 ("Passwords do not match")
             else (Js.Unsafe.coerce pass2)##setCustomValidity("");
             Lwt.return ())))
       }}
       in
       [
         string_input
           ~a:[a_placeholder "Your first name"]
           ~name:fname
           ~value:firstname
           ~input_type:`Text
           ();
         string_input
           ~a:[a_placeholder "Your last name"]
           ~name:lname
           ~value:lastname
           ~input_type:`Text
           ();
         pass1;
         pass2;
         string_input
           ~a:[a_class ["button"]]
           ~input_type:`Submit
           ~value:"Submit"
           ();
       ]) ()


let preregister_form ?a label =
  generic_email_form ?a ~service:%Eba_services.preregister_service' ~label ()

let home_button ?a () =
  form ?a ~service:%Eba_services.main_service
    (fun _ -> [
      string_input
        ~input_type:`Submit
        ~value:"home"
        ();
    ])

let avatar user =
  match Eba_user.avatar_uri_of_user user with
  | Some src ->
    img ~alt:"picture" ~a:[a_class ["eba_avatar"]] ~src ()
  | None -> Ow_icons.F.user ()

let username user =
  let n = match Eba_user.firstname_of_user user with
    | "" ->
      let userid = Eba_user.userid_of_user user in
      [pcdata ("User "^Int64.to_string userid)]
    | s ->
      [pcdata s;
       pcdata " ";
       pcdata (Eba_user.lastname_of_user user);
      ]
  in
  div ~a:[a_class ["eba_username"]] n

let password_form ?a ~service () =
  D.post_form
    ?a
    ~service
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
       ignore {unit{
         let pass1 = To_dom.of_input %pass1 in
         let pass2 = To_dom.of_input %pass2 in
         Lwt_js_events.async
           (fun () ->
              Lwt_js_events.inputs pass2
                (fun _ _ ->
                   ignore
                     (if Js.to_string pass1##value <> Js.to_string pass2##value
                      then
                        (Js.Unsafe.coerce
                           pass2)##setCustomValidity("Passwords do not match")
                      else (Js.Unsafe.coerce pass2)##setCustomValidity(""));
                   Lwt.return ()))
       }};
       [
         table
           [
             tr [td [label [pcdata "Password:"]]; td [pass1]];
             tr [td [label [pcdata "Retype password:"]]; td [pass2]];
           ];
         string_input ~input_type:`Submit ~value:"Send" ()
       ])
    ()

let multiple_email_div_id = "multiple_email"
}}
{server{
let rpc_emails_and_params_of_userid =
  server_function Json.t<int64> Eba_user.emails_and_params_of_userid

let rpc_add_email_to_user =
  let add_email (user, email) =
      Eba_user.add_email_to_user user email
  in
    server_function Json.t<int64 * string> add_email
}}

{client{

module ReactList = struct
    let list t =
      let open ReactiveData.RList in
      make_from
        (React.S.value t)
        (React.E.map (fun e -> Set e) (React.S.changes t))
end

module Model = struct
    type non_primary_mail = {
        email: string;
        is_activated: bool;
        act_key_sent: bool;
      }
    type mails = {userid: int64;
                  add_mail_error: string option;
                  primary: string;
                  others: non_primary_mail list}
    type state = [`NotConnected | `Connected of mails]
    type rs = state React.signal
    type rf = ?step:React.step -> state -> unit
    type rp = rs * rf

    let create_connected userid =
      lwt mails = %rpc_emails_and_params_of_userid userid in
      let f (_, primary, _) = primary in
      let primary, others =  List.partition f mails in
      let (primary, _, _) = List.hd primary in
      let act_key_sent = false in
      let add_mail_error = None in
      let others = List.map
                     (fun (email, is_activated, _) ->
                      {email;
                       is_activated;
                       act_key_sent})
                     others in
      Lwt.return {userid;add_mail_error;
                  primary; others}

    let create userido =
      match userido with
      | None -> Lwt.return `NotConnected
      | Some userid ->
         lwt res = (create_connected userid) in
         Lwt.return (`Connected res)
end

let create_input name =
  Tyxml_js.Html5.(input ~a:[a_input_type `Text; a_placeholder name]) ()

let input_value i = Js.to_string (Tyxml_js.To_dom.of_input i) ## value

let create_button name onclick =
  let b = Tyxml_js.Html5.(button [pcdata name]) in
  let () = Lwt_js_events.(async (fun () -> clicks
                                             (Tyxml_js.To_dom.of_button b)
                                             (fun _ _ -> onclick ()))) in
  b


let multiple_emails_content f model =
  let open Tyxml_js in
  match model with
  | `NotConnected ->  [Html5.(em [pcdata "Please sign-in."])]
  | `Connected emails ->
     let add_input = create_input "New email" in
     let onclick () =
       let value = input_value add_input in
       let userid = emails.Model.userid in
       lwt newmodel =
         try_lwt
           lwt () = %rpc_add_email_to_user (userid, value) in
           Model.create (Some userid)
         with _ ->
           let newmodel = {emails with Model.add_mail_error = Some value} in
           Lwt.return (`Connected newmodel)
       in
       let () = f newmodel in
       Lwt.return_unit
     in
     let button = create_button "Add" onclick in
     let div_content = [add_input; button] in
     let p_mail = Html5.pcdata ("Primary email: " ^ emails.Model.primary) in
     let mail_error = match emails.Model.add_mail_error with
       | None -> []
       | Some error ->
          let msg = Html5.pcdata (error ^ " already exists") in
          let onclick () =
            let newm = {emails with Model.add_mail_error = None} in
            let () = f (`Connected newm) in
            Lwt.return_unit
          in
          [msg; create_button "Clear msg" onclick]
     in
     Html5.([p [em [p_mail]]] @ mail_error @ [div div_content])

let view_multiple_emails ((r, f): Model.rp) =
    let new_elements = React.S.map (multiple_emails_content f) r in
    Tyxml_js.R.Html5.(div (ReactList.list new_elements))

let setup_multiple_emails userid_o =
    let doc = Dom_html.document in
    let parent =
      Js.Opt.get (doc##getElementById(Js.string multiple_email_div_id))
        (fun () -> assert false)
    in
    lwt model = Model.create userid_o in
    let rp = React.S.create model in
    let new_div = Tyxml_js.To_dom.of_div (view_multiple_emails rp) in
    let () = Dom.appendChild parent new_div in
    Lwt.return_unit

 }}
