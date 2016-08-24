
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

 let set_personal_data_handler' =
   Os_session.connected_fun set_personal_data_handler'

 let set_password_handler' =
   Os_session.connected_fun set_password_handler'
]

[%%client

 let set_personal_data_handler' =
   let set_personal_data_rpc =
     ~%(Eliom_client.server_function
	  [%derive.json : ((string * string) * (string * string))]
	@@ set_personal_data_handler' ())
   in
   fun () -> set_personal_data_rpc

 let set_password_handler' () = Os_handlers.set_password_rpc

 let forgot_password_handler =
   let forgot_password_rpc =
     ~%(Eliom_client.server_function [%derive.json : string]
	@@ forgot_password_handler ())
   in
   fun () -> forgot_password_rpc

  let preregister_handler' =
    let preregister_rpc =
      ~%(Eliom_client.server_function [%derive.json : string]
	 @@ preregister_handler' ())
    in
    fun () -> preregister_rpc
     
  let activation_handler =
    let activation_handler_rpc =
      ~%(Eliom_client.server_function [%derive.json : string]
	 @@ fun akey -> activation_handler akey ())
    in
    fun akey () -> activation_handler_rpc akey

]


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

 let settings_handler userid_o () () =
   let%lwt user = %%%MODULE_NAME%%%_container.get_user_data userid_o in
   let content = match user with
     | Some user ->
       %%%MODULE_NAME%%%_content.Settings.settings_content user
     | None -> []
   in
   %%%MODULE_NAME%%%_container.page userid_o content

]
