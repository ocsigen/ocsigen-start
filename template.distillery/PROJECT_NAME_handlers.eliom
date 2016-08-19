
[%%server

 include Os_handlers

 let upload_user_avatar_handler myid () ((), (cropping, photo)) =
   let avatar_dir =
     List.fold_left Filename.concat
       (List.hd !%%%MODULE_NAME%%%_config.avatar_dir)
       (List.tl !%%%MODULE_NAME%%%_config.avatar_dir) in
   let%lwt avatar =
     Os_uploader.record_image avatar_dir ~ratio:1. ?cropping photo in
   let%lwt user = Os_user.user_of_userid myid in
   let old_avatar = Os_user.avatar_of_user user in
   let%lwt () = Os_user.update_avatar avatar myid in
   match old_avatar with
   | None -> Lwt.return ()
   | Some old_avatar ->
     Lwt_unix.unlink (Filename.concat avatar_dir old_avatar )

 let forgot_password_handler =
   forgot_password_handler Os_services.main_service

]

[%%client

  let set_personal_data_handler' =
    let set_personal_data_rpc =
      ~%(Eliom_client.server_function
	   [%derive.json : ((string * string) * (string * string))]
	   (Os_session.connected_rpc
	      (fun id s -> set_personal_data_handler' id () s)))
    in
    fun (_ : int64) () d -> set_personal_data_rpc d

  let set_password_handler' id () p =
    Os_handlers.set_password_rpc p

  let forgot_password_handler =
    let forgot_password_rpc =
      ~%(Eliom_client.server_function
	   [%derive.json : string]
	   (Os_session.Opt.connected_rpc
	      (fun _ mail ->
		forgot_password_handler () mail)))
    in
    fun () mail -> forgot_password_rpc mail

  let preregister_handler' =
    let preregister_rpc =
      ~%(Eliom_client.server_function
	   [%derive.json : string]
	   (Os_session.Opt.connected_rpc
	      (fun _ mail -> preregister_handler' () mail)))
    in
    fun () mail -> preregister_rpc mail
     
  let activation_handler =
    let activation_handler_rpc =
      ~%(Eliom_client.server_function
	   [%derive.json : string]
	   (Os_session.Opt.connected_rpc
	      (fun _ akey -> activation_handler akey ())))
    in
    fun akey () -> activation_handler_rpc akey

]

let%shared password_form ~service () = Eliom_content.Html.D.(
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


[%%shared

 let main_service_handler userid_o () () = Eliom_content.Html.F.(
  %%%MODULE_NAME%%%_container.page userid_o (
    [
      p [em [pcdata "Eliom base app: Put app content here."]]
    ]
  )
 )

 let about_handler userid_o () () = Eliom_content.Html.F.(
  %%%MODULE_NAME%%%_container.page userid_o [
    div [
      p [pcdata "This template provides a skeleton \
                 for an Ocsigen application."];
      br ();
      p [pcdata "Feel free to modify the generated code and use it \
                 or redistribute it as you want."]
    ]
  ]
 )

 let settings_handler =
   let settings_content =
     let none = [%client ((fun () -> ()) : unit -> unit)] in
     fun user ->
       Eliom_content.Html.D.(
	 [
	   div ~a:[a_class ["eba-welcome-box"]] [
	     p [pcdata "Change your password:"];
	     password_form ~service:Os_services.set_password_service' ();
	     br ();
	     Os_userbox.upload_pic_link
	       none
	       %%%MODULE_NAME%%%_services.upload_user_avatar_service
	       (Os_user.userid_of_user user);
	     br ();
	     Os_userbox.reset_tips_link none;
	   ]
	 ]
       )
   in
   fun userid_o () () ->
     let%lwt user = %%%MODULE_NAME%%%_container.get_user_data userid_o in
     let content = match user with
       | Some user ->
	 settings_content user
       | None -> []
     in
     %%%MODULE_NAME%%%_container.page userid_o content

]
