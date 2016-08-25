[%%shared.start]

module Forms = struct

  let password_form ~service () = Eliom_content.Html.D.(
    Form.post_form
      ~service
      (fun (pwdn, pwd2n) ->
	let pass1 =
          Form.input
            ~a:[a_required ();
		a_autocomplete false;
		a_placeholder "password"]
            ~input_type:`Password
	    ~name:pwdn
            Form.string
	in
	let pass2 =
          Form.input
            ~a:[a_required ();
		a_autocomplete false;
		a_placeholder "retype your password"]
            ~input_type:`Password
	    ~name:pwd2n
            Form.string
	in
	ignore [%client (
          let pass1 = Eliom_content.Html.To_dom.of_input ~%pass1 in
          let pass2 = Eliom_content.Html.To_dom.of_input ~%pass2 in
          Lwt_js_events.async
            (fun () ->
              Lwt_js_events.inputs pass2
                (fun _ _ ->
                  ignore (
		    if Js.to_string pass1##.value <> Js.to_string pass2##.value
                    then
		      (Js.Unsafe.coerce pass2)##(setCustomValidity ("Passwords do not match"))
                    else (Js.Unsafe.coerce pass2)##(setCustomValidity ("")));
                  Lwt.return ()))
	    : unit)];
	[
          table
            [
              tr [td [pass1]];
              tr [td [pass2]];
            ];
          Form.input ~input_type:`Submit
            ~a:[ a_class [ "button" ] ] ~value:"Send" Form.string
	])
      ()
  )

end

module Connection = struct

  let connect_form () = Eliom_content.Html.D.(
    Form.post_form ~service:Os_services.connect_service
      (fun ((login, password), keepmeloggedin) -> [
	Form.input
          ~a:[a_placeholder "Your email"]
          ~name:login
          ~input_type:`Email
          Form.string;
	Form.input
          ~a:[a_placeholder "Your password"]
          ~name:password
          ~input_type:`Password
          Form.string;
	Form.bool_checkbox_one
          ~a:[a_checked ()]
          ~name:keepmeloggedin
          ();
	span [pcdata "keep me logged in"];
	Form.input
          ~a:[a_class ["button"]]
          ~input_type:`Submit
          ~value:"Sign in"
          Form.string;
      ]) ()
  )

  let sign_up_form () =
    Os_view.generic_email_form ~service:Os_services.sign_up_service' ()

  let forgot_password_form () =
    Os_view.generic_email_form ~service:Os_services.forgot_password_service ()

  let forgotpwd_button () = Eliom_content.Html.D.(
    let popup_content = fun () -> Lwt.return @@
      div ~a:[a_class ["navbar-inverse";"os-login-menu"]]
      [forgot_password_form ()] in
    let button_name = "forgot your password?" in
    Os_tools.popup_button
      ~button_name
      ~button_class:["button"]
      ~popup_content
  )

  let sign_in_button () = Eliom_content.Html.D.(
    let popup_content = fun () -> Lwt.return @@
      div ~a:[a_class ["navbar-inverse";"os-login-menu"]]
      [connect_form ()] in
    let button_name = "Sign In" in
    Os_tools.popup_button
      ~button_name
      ~button_class:["button"]
      ~popup_content
  )

  let sign_up_button () = Eliom_content.Html.D.(
    let popup_content = fun () -> Lwt.return @@
      div ~a:[a_class ["navbar-inverse";"os-login-menu"]]
      [sign_up_form ()] in
    let button_name = "Sign Up" in
    Os_tools.popup_button
      ~button_name
      ~button_class:["button"]
      ~popup_content
  )

  let disconnect_button () = Eliom_content.Html.D.(
    Form.post_form ~service:Os_services.disconnect_service
      (fun _ -> [
        Form.button_no_value
          ~a:[ a_class ["button"] ]
          ~button_type:`Submit
          [Ot_icons.F.signout (); pcdata "Logout"]
      ]) ()
  )

end

let%server remove_email_from_user =
  Os_session.connected_rpc (fun userid email ->
    Os_user.remove_email_from_user ~userid ~email)

let%client remove_email_from_user =
  ~%(Eliom_client.server_function [%derive.json : string]
       remove_email_from_user)

let%server email_is_validated =
  Os_session.connected_rpc Os_db.User.get_email_validated

let%server is_main_email =
  Os_session.connected_rpc (fun userid email ->
    Os_user.is_main_email ~userid ~email)

let%server update_main_email =
  Os_session.connected_rpc (fun userid email ->
    Os_user.update_main_email ~userid ~email)

let%client update_main_email =
  ~%(Eliom_client.server_function [%derive.json : string] update_main_email)

let%server update_main_email_button email =
  let open Eliom_content.Html in
  let%lwt validated = email_is_validated email in
  Lwt.return @@ if validated then
      let button = 
	D.button ~a:[D.a_class ["button"]] [D.pcdata "Set as main e-mail"] in
      ignore [%client (Lwt.async (fun () ->
	Lwt_js_events.clicks
	  (Eliom_content.Html.To_dom.of_element ~%button)
	  (fun _ _ ->
	    let%lwt () = update_main_email ~%email in
	    Eliom_client.change_page
	      ~service:%%%MODULE_NAME%%%_services.settings_service () ()
	  )
      ) : unit) ];
      button
    else
      F.div []

let%server delete_email_button email =
  let open Eliom_content.Html in
  let button = D.button ~a:[D.a_class ["button"]] [D.pcdata "X"] in
  ignore [%client (Lwt.async (fun () ->
    Lwt_js_events.clicks
      (Eliom_content.Html.To_dom.of_element ~%button)
      (fun _ _ ->
	let%lwt () = remove_email_from_user ~%email in
	Eliom_client.change_page
	  ~service:%%%MODULE_NAME%%%_services.settings_service () ()
      )
  ) : unit) ];
  button

let%server tr_of_email main_email email =
  let open Eliom_content.Html.F in
  let%lwt validated = email_is_validated email in
  let valid = p [
    pcdata @@
      if validated
      then "validated"
      else "still waiting for confirmation"
  ] in
  let del_button, up_button =
    if email = main_email
    then (div [], Lwt.return @@ p [pcdata "Main e-mail"])
    else (delete_email_button email, update_main_email_button email)
  in
  let%lwt up_button = up_button in
  let email = p [pcdata email] in
  Lwt.return @@ tr [td [del_button]; td [valid]; td [email]; td [up_button]]

let%server emails_table userid : [`Table] Eliom_content.Html.elt Lwt.t =
  let open Eliom_content.Html.F in
  let open Lwt in
  let%lwt main_email = Os_db.User.email_of_userid userid in
  let%lwt l =
    Os_db.User.emails_of_userid userid
  in
  let tr_of_email = tr_of_email main_email in
  let%lwt tr_list = Lwt_list.map_s tr_of_email l in
  Lwt.return @@ table tr_list

let%client emails_table =
  ~%(Eliom_client.server_function [%derive.json : int64] emails_table)

let%shared emails_table uid = 
  (emails_table uid :> Html_types.div_content_fun Eliom_content.Html.elt Lwt.t)


module Settings = struct

  let settings_content =
    let none = [%client ((fun () -> ()) : unit -> unit)] in
    fun user ->
      let%lwt emails = emails_table @@ Os_user.userid_of_user user in
      Lwt.return @@
      Eliom_content.Html.D.(
	[
	  div ~a:[a_class ["os-welcome-box"]] [
	    p [pcdata "Change your password:"];
	    Forms.password_form ~service:Os_services.set_password_service' ();
	    br ();
	    Os_userbox.upload_pic_link
	      none
              %%%MODULE_NAME%%%_services.upload_user_avatar_service
	      (Os_user.userid_of_user user);
	    br ();
	    Os_userbox.reset_tips_link none;
	    br ();
	    p [pcdata "Link a new email to your account:"];
	    Os_view.generic_email_form ~service:Os_services.add_email_service ();
	    p [pcdata "currently registered emails:"];
	    emails
	  ]
	]
      )

  let settings_button () = Eliom_content.Html.D.(
    let button =
      button ~a:[a_class ["btn";"button"]] [pcdata "Settings"]
    in
    ignore
      [%client
          (Lwt.async (fun () ->
            Lwt_js_events.clicks
              (Eliom_content.Html.To_dom.of_element ~%button)
              (fun _ _ ->
		Eliom_client.change_page
		  ~service:%%%MODULE_NAME%%%_services.settings_service () ()
	      )
	   )
             : _)
      ];
    div [button]
  )

end
