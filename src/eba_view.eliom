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
    (fun ((login, password), keepmeloggedin) -> [
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
      bool_checkbox
        ~a:[a_checked `Checked]
        ~name:keepmeloggedin
        ();
      span [pcdata "keep me logged in"];
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
  D.post_form ?a ~service:%Eba_services.forgot_password_service
    (fun (email, primary_email) ->
      [string_input
         ~a:[a_placeholder "e-mail address"]
         ~input_type:`Email
         ~name:email
         ();
       string_input
         ~a:[a_placeholder "(optional) primary e-mail address"]
         ~input_type:`Email
         ~name:primary_email
         ();
       string_input
         ~a:[a_class ["button"]]
         ~input_type:`Submit
         ~value:"Send"
         ()]) ()

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

let rpc_update_users_primary_email =
  let update_primary_email (user, email) =
    Eba_user.update_users_primary_email user email
  in
  server_function Json.t<int64 * string> update_primary_email

let rpc_delete_email =
  let delete_email (user, email) =
    Eba_user.delete_email user email
  in
  server_function Json.t<int64 * string> delete_email

let rpc_send_mail_confirmation =
  let send_mail_confirmation (user, email) =
    Eba_user.send_mail_confirmation user email
  in
  server_function Json.t<int64 * string> send_mail_confirmation
}}

{client{

module Model = struct
    type activation_state = [`Act_key_sent | `Activated]
    type non_primary_mail = {
        email: string;
        activation_state: activation_state;
      }

    type message_type = [`Error | `Info]
    type message_to_user = {
        msg_type: message_type;
        msg: string;
    }
    type mails = {userid: int64;
                  message: message_to_user option;
                  primary: string;
                  others: non_primary_mail list}
    type state = mails
    type rs = state React.signal
    type rf = ?step:React.step -> state -> unit
    type rp = rs * rf
    let activation_key_sent_msg = {msg_type=`Info;
                                   msg="Activation key sent"}
    let create_connected userid =
      lwt mails = %rpc_emails_and_params_of_userid userid in
      let f (_, primary, _) = primary in
      let primary, others =  List.partition f mails in
      let (primary, _, _) = List.hd primary in
      let message = None in
      let others = List.map
                     (fun (email, _, is_activated) ->
                      let activation_state =
                        if is_activated then `Activated
                        else `Act_key_sent
                      in
                      {email;
                       activation_state})
                     others in
      Lwt.return {userid; message;
                  primary; others}

    let create ?msg userid =
      lwt res = create_connected userid in
      Lwt.return {res with message=msg}
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

let create_add_email_div emails f =
  let open Tyxml_js in
  let add_input = create_input "New email" in
  let onclick () =
    let value = input_value add_input in
    let userid = emails.Model.userid in
    lwt newmodel =
      try_lwt
        lwt () = %rpc_add_email_to_user (userid, value) in
        (* we send the activation key straight away *)
        lwt () = %rpc_send_mail_confirmation (emails.Model.userid,
                                              value) in
        Model.(create ~msg:activation_key_sent_msg userid)
      with _ ->
        let msg = value in
        let msg_type = `Error in
        let new_msg = Model.(Some {msg; msg_type}) in
        let newmodel = Model.({emails with message=new_msg}) in
        Lwt.return newmodel
    in
    let () = f newmodel in
    Lwt.return_unit
  in
  let button = create_button "Add" onclick in
  let div_content = [add_input; button] in
  Html5.(div div_content)

let add_message emails f =
  let open Tyxml_js in
  match emails.Model.message with
  | None -> []
  | Some msg_to_display ->
     let msg =
       Model.(match msg_to_display.msg_type with
              | `Error -> (msg_to_display.msg ^ " already exists")
              | `Info -> (msg_to_display.msg))
     in
     let msg = Html5.pcdata msg in
     let onclick () =
       let newm = {emails with Model.message = None} in
       let () = f newm in
       Lwt.return_unit
     in
     [msg; create_button "Clear msg" onclick]

let show_one_other emails other f =
  let open Tyxml_js in
  let msg = Html5.pcdata other.Model.email in
  let after_msg =
    match other.Model.activation_state with
    | `Act_key_sent ->
       let onclick () =
         let this, new_others = Model.(List.partition
                                         (fun x -> x.email = other.email)
                                         emails.others) in
         let this = List.hd this in
         lwt () = %rpc_send_mail_confirmation (emails.Model.userid,
                                               this.Model.email) in
         let this = Model.({this with activation_state=`Act_key_sent}) in
         let others = this :: new_others in
         let msg = Some (Model.activation_key_sent_msg) in
         let newm = Model.({emails with others = others;
                                        message = msg}) in
         let () = f newm in
         Lwt.return_unit
       in
       create_button "Resend activation link" onclick
    | `Activated ->
       let onclick () =
         lwt () = Model.(%rpc_update_users_primary_email
                            (emails.userid,
                             other.email)) in
         lwt newf = Model.(create_connected emails.userid) in
         let () = f newf in
         Lwt.return_unit
       in
       (* we ensure here that an activated mail only
          can be set as primary *)
       create_button "Set as primary" onclick
  in
  let ondeleteclick () =
    lwt () = %rpc_delete_email Model.(emails.userid, other.email) in
    lwt newf = Model.(create_connected emails.userid) in
    let () = f newf in
    Lwt.return_unit
  in
  let delete = create_button "Delete" ondeleteclick in
  Html5.(div [msg; after_msg; delete])

let show_others emails f =
  List.map (fun x -> show_one_other emails x f) emails.Model.others

let multiple_emails_content f emails =
  let open Tyxml_js in
  let p_mail = Html5.pcdata ("Primary email: " ^ emails.Model.primary) in
  let add_ui = create_add_email_div emails f in
  let add_error_ui = add_message emails f in
  let others = show_others emails f in
  Html5.([p [p_mail]] @ add_error_ui @ [add_ui] @ others)

let view_multiple_emails ((r, f): Model.rp) =
    let new_elements = React.S.map (multiple_emails_content f) r in
    Tyxml_js.R.Html5.(div (ReactiveData.RList.make_from_s new_elements))

let setup_multiple_emails userid =
  let doc = Dom_html.document in
  (* XXX this could be avoided using Eliom_csreact *)
  let rec pollParentDiv () =
    match (Js.Opt.to_option
             (doc##getElementById(Js.string multiple_email_div_id)))
    with
      | None -> begin
          lwt () = Lwt_js.sleep 0.1 in
          pollParentDiv ()
        end
      | Some elt -> Lwt.return elt
  in
  lwt parent = pollParentDiv () in
  lwt model = Model.create userid in
  let rp = React.S.create model in
  let new_div = Tyxml_js.To_dom.of_div (view_multiple_emails rp) in
  let () = Dom.appendChild parent new_div in
  Lwt.return_unit
}}
