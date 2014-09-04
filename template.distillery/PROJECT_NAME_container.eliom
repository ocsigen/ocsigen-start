{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
  open %%%MODULE_NAME%%%_tools
}}

let header ?user () =
  lwt user_box = %%%MODULE_NAME%%%_userbox.userbox user in
  Lwt.return
    (div ~a:[a_id "%%%PROJECT_NAME%%%-header"] [
      a ~a:[a_id "%%%PROJECT_NAME%%%-logo"]
        ~service:%%%MODULE_NAME%%%_services.main_service [
          pcdata Ebapp.App.application_name;
        ] ();
      ul ~a:[a_id "%%%PROJECT_NAME%%%-navbar"]
        [
          li [a ~service:%%%MODULE_NAME%%%_services.main_service
                [pcdata "Home"] ()];
          li [a ~service:%%%MODULE_NAME%%%_services.about_service
                [pcdata "About"] ()]
        ];
      user_box;
    ])

let footer ?user () =
  div ~a:[a_id "%%%PROJECT_NAME%%%-footer"] [
    pcdata "This application has been generated using the ";
    a ~service:%%%MODULE_NAME%%%_services.eba_github_service [
      pcdata "Eliom-base-app"
    ] ();
    pcdata " template for Eliom-distillery and uses the ";
    a ~service:%%%MODULE_NAME%%%_services.ocsigen_service [
      pcdata "Ocsigen"
    ] ();
    pcdata " technology.";
  ]

let connected_welcome_box () =
  let info, ((fn, ln), (p1, p2)) =
    match Eliom_reference.Volatile.get Eba_msg.wrong_pdata with
    | None ->
      p [
        pcdata "Your personal information has not been set yet.";
        br ();
        pcdata "Please take time to enter your name and to set a password."
      ], (("", ""), ("", ""))
    | Some wpd -> p [pcdata "Wrong data. Please fix."], wpd
  in
  (div ~a:[a_id "eba_welcome_box"]
     [
       div [h2 [pcdata ("Welcome to "^Ebapp.App.application_name)];
            info];
       %%%MODULE_NAME%%%_view.information_form
         ~firstname:fn ~lastname:ln
         ~password1:p1 ~password2:p2
         ()
     ])

let page uid_o cnt =
  lwt user = match uid_o with None -> Lwt.return None
    | Some uid -> lwt u = %%%MODULE_NAME%%%_user.user_of_uid uid in
                  Lwt.return (Some u)
  in
  let l =
    [ div ~a:[a_id "%%%PROJECT_NAME%%%-body"] cnt;
      footer ?user ();
    ]
  in
  lwt h = header ?user () in
  Lwt.return
    (h
     ::match user with
       | Some user when (not (%%%MODULE_NAME%%%_user.is_complete user)) ->
         connected_welcome_box () :: l
       | _ -> l)
