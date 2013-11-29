{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
  open Foobar_tools
}}

let header ?user () =
  let navbar_cls =
    match user with
      | None -> ["absolute"; "right"]
      | Some _ -> ["inline-block"]
  in
  let user_box =
    match user with
      | None -> nothing ()
      | Some user ->
          div ~a:[a_id "foobar-user-box"; a_class ["absolute"; "right"; "bottom"]] [
            Foobar_view.disconnect_button ();
          ]
  in
  div ~a:[a_id "foobar-header"; a_class ["center"]] [
    a ~a:[a_id "foobar-logo"]
      ~service:Foobar_services.main_service [
        pcdata Ebapp.App.app_name;
      ] ();
    div ~a:[a_id "foobar-navbar"; a_class ("bottom"::navbar_cls)] [
      a ~a:[a_class ["item"; "left-bar"]]
        ~service:Foobar_services.main_service [
          pcdata "Home";
        ] ();
      a ~a:[a_class ["item"; "left-bar"]]
        ~service:Foobar_services.about_service [
          pcdata "About";
        ] ();
    ];
    user_box;
  ]

let footer ?user () =
  div ~a:[a_id "foobar-footer"; a_class ["center"]] [
    span ~a:[a_class ["eba-template"]] [
      pcdata "This application has been generated using ";
      a ~service:Foobar_services.eba_github_service [
        pcdata "Eliom-base-app"
      ] ();
      pcdata " template and uses ";
      a ~service:Foobar_services.ocsigen_service [
        pcdata "Ocsigen project"
      ] ();
      pcdata " technology.";
    ];
  ]

let page ?user cnt =
  [
    header ?user ();
    div ~a:[a_id "foobar-body"; a_class ["center"]]
      (div ~a:[a_id "foobar-request-msgs"]
         ( (List.map (Ebapp.Reqm.to_html) (Ebapp.Reqm.to_list Foobar_reqm.notice_set))
         @ (List.map (Ebapp.Reqm.to_html) (Ebapp.Reqm.to_list Foobar_reqm.error_set)))
       ::cnt);
    footer ?user ();
  ]
