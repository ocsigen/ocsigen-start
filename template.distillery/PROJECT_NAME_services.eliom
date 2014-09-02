open Eliom_parameter

let main_service =
  Eliom_service.App.service
    ~path:[]
    ~get_params:unit ()

let forgot_password_service =
  Eliom_service.App.service
    ~path:["forgot-password"]
    ~get_params:unit ()

let preregister_service' =
  Eliom_service.Http.post_coservice'
    ~name:"preregister_service"
    ~post_params:(string "email")
    ()

let about_service =
  Eliom_service.App.service
    ~path:["about"]
    ~get_params:unit ()

let forgot_password_service' =
  Eliom_service.Http.post_coservice'
    ~name:"lost_password"
    ~post_params:(string "email")
    ()

let set_personal_data_service' =
  Eliom_service.Http.post_coservice'
    ~name:"set_data"
    ~post_params:(
      (string "firstname" ** string "lastname")
      ** (string "password" ** string "password2"))
    ()

let sign_up_service' =
  Eliom_service.Http.post_coservice'
    ~name:"sign_up"
    ~post_params:(string "email")
    ()

let connect_service =
  Eliom_service.Http.post_coservice'
    ~name:"connect"
    ~post_params:(string "login" ** string "password") ()

let disconnect_service =
  Eliom_service.Http.post_coservice'
    ~name:"disconnect"
    ~post_params:unit ()

let activation_service =
  Eliom_service.Http.coservice'
    ~name:"activation"
    ~get_params:(string "activationkey") ()

let eba_github_service =
  Eliom_service.Http.external_service
    ~prefix:"http://github.com"
    ~path:["ocsigen"; "eliom-base-app"]
    ~get_params:Eliom_parameter.unit ()

let ocsigen_service =
  Eliom_service.Http.external_service
    ~prefix:"http://ocsigen.org"
    ~path:[]
    ~get_params:Eliom_parameter.unit ()

let set_password_service' =
  Eliom_service.Http.post_coservice'
    ~name:"set_password"
    ~post_params:(string "password" ** string "password2")
    ()
