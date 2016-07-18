
let%shared nav_elts = [
  ("Home",Eba_services.main_service);
  ("About",%%%MODULE_NAME%%%_services.about_service);
  ("Demo",%%%MODULE_NAME%%%_services.otdemo_service)
]

let%shared navigation_bar () = Eba_tools.NavigationBar.of_elt_list
  ~ul_class:["nav";"navbar-nav"]
  nav_elts
