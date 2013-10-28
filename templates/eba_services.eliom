module type T = sig
  val lost_password_service :
    (unit, string,
     [> `Nonattached of [> `Post ] Eliom_service.na_s ],
     [ `WithoutSuffix ], unit,
     [ `One of string ] Eliom_parameter.param_name,
     [< Eliom_service.registrable > `Registrable ],
     [> Eliom_service.http_service ])
    Eliom_service.service
  val sign_up_service :
    (unit, string,
     [> `Nonattached of [> `Post ] Eliom_service.na_s ],
     [ `WithoutSuffix ], unit,
     [ `One of string ] Eliom_parameter.param_name,
     [< Eliom_service.registrable > `Registrable ],
     [> Eliom_service.http_service ])
    Eliom_service.service
  val set_password_service :
    (unit, string * string,
     [> `Nonattached of [> `Post ] Eliom_service.na_s ],
     [ `WithoutSuffix ], unit,
     [ `One of string ] Eliom_parameter.param_name *
     [ `One of string ] Eliom_parameter.param_name,
     [< Eliom_service.registrable > `Registrable ],
     [> Eliom_service.http_service ])
    Eliom_service.service
  val set_personal_data_service :
    (unit, (string * string) * (string * string),
     [> `Nonattached of [> `Post ] Eliom_service.na_s ],
     [ `WithoutSuffix ], unit,
     ([ `One of string ] Eliom_parameter.param_name *
      [ `One of string ] Eliom_parameter.param_name) *
     ([ `One of string ] Eliom_parameter.param_name *
      [ `One of string ] Eliom_parameter.param_name),
     [< Eliom_service.registrable > `Registrable ],
     [> Eliom_service.http_service ])
    Eliom_service.service
  (*
   val preregister_service :
   (unit, string,
   [> `Nonattached of [> `Post ] Eliom_service.na_s ],
   [ `WithoutSuffix ], unit,
   [ `One of string ] Eliom_parameter.param_name,
   [< Eliom_service.registrable > `Registrable ],
   [> Eliom_service.http_service ])
   Eliom_service.service
   *)
  val admin_service :
    (unit, unit,
     [> `Attached of
        ([> `Internal of [> `Service ] ], [> `Get ])
          Eliom_service.a_s ],
     [ `WithoutSuffix ], unit, unit,
     [< Eliom_service.registrable > `Registrable ],
     [> Eliom_service.appl_service ])
    Eliom_service.service
  val crop_service : Ew_dyn_upload.dynup_service_t
end

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

let set_password_service =
  Eliom_service.Http.post_coservice'
    ~name:"setpassword"
    ~post_params:(string "password1" ** string "password2") ()

let set_personal_data_service =
  Eliom_service.Http.post_coservice'
    ~name:"setdata"
    ~post_params:((string "firstname" ** string "lastname")
                  ** (string "password" ** string "password2")) ()

    (*
let preregister_service =
  Eliom_service.Http.post_coservice'
    ~name:"preregister"
    ~post_params:(string "email") ()
     *)

let admin_service =
  Eliom_service.App.service
    ~path:["admin"]
    ~get_params:unit ()

let crop_service =
  Ew_dyn_upload.service
    ~name:"crop"
    ()
