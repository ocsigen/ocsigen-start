(* Copyright Vincent Balat *)

open Eliom_service
open Eliom_parameter

(********* Services *********)
let main_service = service ~path:[] ~get_params:unit ()

let login_service =
  post_coservice'
    ~name:"login" ~post_params:(string "login" ** string "password") ()

let logout_service =
  post_coservice' ~name:"logout" ~post_params:unit ()

let ask_activation_service =
  (* Ask to receive an activation email
     (and possibly create the account, if not created) *)
  post_coservice'
    ~keep_get_na_params:false
    ~name:"activation" ~post_params:(string "email") ()

let activation_service =
  coservice' ~name:"activation" ~get_params:(string "activationkey") ()

let set_personal_data_service =
  post_coservice'
    ~name:"setdata"
    ~post_params:((string "firstname" ** string "lastname")
                  ** (string "password" ** string "password2")) ()


let get_userlist_for_completion_service =
  (* Make a request to DB to get the list of users *)
  post_coservice' ~name:"userslist" ~post_params:(string "prefix") ()

let pic_service =
  post_coservice' ~name:"upload_pic" ~post_params:(file "f") ()

let preregister_service =
  post_coservice'
    ~name:"preregister"
    ~post_params:(string "email") ()
