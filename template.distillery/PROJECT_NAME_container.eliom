{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
  open %%%MODULE_NAME%%%_tools
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
          div ~a:[a_id "%%%PROJECT_NAME%%%-user-box"; a_class ["absolute"; "right"; "bottom"]] [
            %%%MODULE_NAME%%%_view.disconnect_button ();
          ]
  in
  div ~a:[a_id "%%%PROJECT_NAME%%%-header"; a_class ["center"]] [
    a ~a:[a_id "%%%PROJECT_NAME%%%-logo"]
      ~service:%%%MODULE_NAME%%%_services.main_service [
        pcdata Ebapp.App.app_name;
      ] ();
    div ~a:[a_id "%%%PROJECT_NAME%%%-navbar"; a_class ("bottom"::navbar_cls)] [
      a ~a:[a_class ["item"; "left-bar"]]
        ~service:%%%MODULE_NAME%%%_services.main_service [
          pcdata "Home";
        ] ();
      a ~a:[a_class ["item"; "left-bar"]]
        ~service:%%%MODULE_NAME%%%_services.about_service [
          pcdata "About";
        ] ();
    ];
    user_box;
  ]

let footer ?user () =
  div ~a:[a_id "%%%PROJECT_NAME%%%-footer"; a_class ["center"]] [
    span ~a:[a_class ["eba-template"]] [
      pcdata "This application has been generated using the ";
      a ~service:%%%MODULE_NAME%%%_services.eba_github_service [
        pcdata "Eliom-base-app"
      ] ();
      pcdata " template for Eliom-distillery and uses the ";
      a ~service:%%%MODULE_NAME%%%_services.ocsigen_service [
        pcdata "Ocsigen"
      ] ();
      pcdata " technology.";
    ];
  ]

let page ?user cnt =
  [
    header ?user ();
    div ~a:[a_id "%%%PROJECT_NAME%%%-body"; a_class ["center"]]
      (div ~a:[a_id "%%%PROJECT_NAME%%%-request-msgs"]
         ( (List.map (Ebapp.Reqm.to_html) (Ebapp.Reqm.to_list %%%MODULE_NAME%%%_reqm.notice_set))
         @ (List.map (Ebapp.Reqm.to_html) (Ebapp.Reqm.to_list %%%MODULE_NAME%%%_reqm.error_set)))
       ::cnt);
    footer ?user ();
  ]
