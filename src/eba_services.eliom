(* Copyright Vincent Balat *)

open Eliom_parameter

module type T = sig
  val main_service :
    (unit, unit,
     [> `Attached of
        ([> `Internal of [> `Service ] ], [> `Get ])
          Eliom_service.a_s ],
     [ `WithoutSuffix ], unit, unit,
     [< Eliom_service.registrable > `Registrable ],
     [> Eliom_service.appl_service ])
    Eliom_service.service
  val connect_service :
    (unit, string * string,
     [> `Nonattached of [> `Post ] Eliom_service.na_s ],
     [ `WithoutSuffix ], unit,
     [ `One of string ] Eliom_parameter.param_name *
     [ `One of string ] Eliom_parameter.param_name,
     [< Eliom_service.registrable > `Registrable ],
     [> Eliom_service.http_service ])
    Eliom_service.service
  val disconnect_service :
    (unit, unit,
     [> `Nonattached of [> `Post ] Eliom_service.na_s ],
     [ `WithoutSuffix ], unit, unit,
     [< Eliom_service.registrable > `Registrable ],
     [> Eliom_service.http_service ])
    Eliom_service.service
  val activation_service :
    (string, unit,
     [> `Nonattached of [> `Get ] Eliom_service.na_s ],
     [ `WithoutSuffix ],
     [ `One of string ] Eliom_parameter.param_name, unit,
     [< Eliom_service.registrable > `Registrable ],
     [> Eliom_service.http_service ])
    Eliom_service.service
end

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

let activation_service =
  Eliom_service.Http.coservice'
    ~name:"activation"
    ~get_params:(string "activationkey") ()
