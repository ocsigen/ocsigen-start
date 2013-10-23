(* Copyright Vincent Balat *)

open Eliom_parameter

(********* Services *********)
let main_service =
  Eliom_service.App.service
    ~path:[]
    ~get_params:unit ()

let connect_service =
  Eliom_service.Http.post_coservice'
    ~name:"connect"
    ~post_params:(string "login" ** string "password") ()

let disconnect_service =
  Eliom_service.Http.post_coservice'
    ~name:"disconnect"
    ~post_params:unit ()

let lost_password_service =
  (* Ask to receive an activation key if the user exists *)
  Eliom_service.Http.post_coservice'
    ~keep_get_na_params:false
    ~name:"lost_password"
    ~post_params:(string "email") ()

let sign_up_service =
  (* Ask to receive an activation key if the user does not exist *)
  Eliom_service.Http.post_coservice'
    ~keep_get_na_params:false
    ~name:"sign_up"
    ~post_params:(string "email") ()

let activation_service =
  Eliom_service.Http.coservice'
    ~name:"activation"
    ~get_params:(string "activationkey") ()

let set_password_service =
  Eliom_service.Http.post_coservice'
    ~name:"setpassword"
    ~post_params:(string "password1" ** string "password2") ()

let set_personal_data_service =
  Eliom_service.Http.post_coservice'
    ~name:"setdata"
    ~post_params:((string "firstname" ** string "lastname")
                  ** (string "password" ** string "password2")) ()

let preregister_service =
  Eliom_service.Http.post_coservice'
    ~name:"preregister"
    ~post_params:(string "email") ()

let admin_service =
  Eliom_service.App.service
    ~path:["admin"]
    ~get_params:unit ()

let crop_service =
  Ew_dyn_upload.service
    ~name:"crop"
    ()
