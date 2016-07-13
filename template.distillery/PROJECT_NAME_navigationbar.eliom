let%shared navigationbar () = Eliom_content.Html.F.(
  ul ~a:[a_class ["nav";"navbar-nav"]] [
    li ~a:[a_class [""]] [a ~service:Eba_services.main_service
           [pcdata "Home"] ()];
    li ~a:[a_class [""]] [a ~service:%%%MODULE_NAME%%%_services.about_service
           [pcdata "About"] ()];
    li ~a:[a_class [""]] [a ~service:%%%MODULE_NAME%%%_services.otdemo_service
           [pcdata "ocsigen-toolkit demo"] ()]
  ] |> Lwt.return
)
