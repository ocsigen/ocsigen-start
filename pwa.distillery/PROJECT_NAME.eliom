[%%shared
    open Eliom_lib
    open Eliom_content
    open Html.D
]

module %%%MODULE_NAME%%%_app =
  Eliom_registration.App (
    struct
      let application_name = "%%%PROJECT_NAME%%%"
      let global_data_path = None
    end)

let main_service =
  Eliom_service.create
    ~path:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

[%%client 
  let self = ServiceWorker.get_self () in
  let swReg = self##.navigator##.serviceWorker##register (Js.string "service_worker.js") in
  ignore (
    Promise._then swReg
      ~catch:(fun _ -> 
        Promise.resolve_value (
          Firebug.console##log (Js.string "ServiceWorker cannot be registered")))
      (fun _ -> 
         Promise.resolve_value (
           Firebug.console##log (Js.string "ServiceWorker is registered")))) 
]

let () =
  %%%MODULE_NAME%%%_app.register
    ~service:main_service
    (fun () () ->
      Lwt.return
        (Eliom_tools.F.html
           ~title:"%%%PROJECT_NAME%%%"
           ~css:[["css";"%%%PROJECT_NAME%%%.css"]]
           Html.F.(body [
             h1 [pcdata "Welcome from Eliom's distillery!"];
           ])))
