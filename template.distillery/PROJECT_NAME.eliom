{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

let main_service_handler uid_o gp pp =
  %%%MODULE_NAME%%%_container.page uid_o (
    [
     p [em [pcdata "Eliom base app: Put app content here."]]
    ]
  )

let about_handler uid_o () () =
  %%%MODULE_NAME%%%_container.page uid_o [
    div [
      p [pcdata "This template provides a skeleton \
                 for an Ocsigen application."];
      hr ();
      p [pcdata "Feel free to modify the generated code and use it \
                 or redistribute it as you want."]
    ]
  ]


let () =
  Ebapp.App.register
    Eba_services.main_service
    (Ebapp.Page.Opt.connected_page main_service_handler);

  Ebapp.App.register
    Eba_services.about_service
    (Ebapp.Page.Opt.connected_page about_handler)
