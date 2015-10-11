(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
 *
 * Copyright (C) 2014
 *      Charly Chevalier
 *      Vincent Balat
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

open Eliom_parameter

let main_service =
  Eliom_service.App.service
    ~path:[]
    ~get_params:unit ()

let preregister_service' =
  Eliom_service.Http.post_coservice'
    ~name:"preregister_service"
    ~post_params:(string "email")
    ()

let forgot_password_service =
  Eliom_service.Http.post_coservice'
    ~name:"lost_password"
    ~post_params:(string "email")
    ()

let set_personal_data_service' =
  Eliom_service.Http.post_coservice'
    ~name:"set_data"
    ~post_params:(
      (string "firstname" ** string "lastname") **
      (string "password"  ** string "password2"))
    ()

let sign_up_service' =
  Eliom_service.Http.post_coservice'
    ~name:"sign_up"
    ~post_params:(string "email")
    ()

let connect_service =
  Eliom_service.Http.post_coservice'
    ~name:"connect"
    ~post_params:(string "username" ** string "password") ()

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

let manage_email_service =
  Eliom_service.App.service
    ~path:["manage_emails"]
    ~get_params:unit ()
