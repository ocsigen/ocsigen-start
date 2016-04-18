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

[%%shared
open Eliom_parameter

let main_service =
  Eliom_service.create
    ~ret:Eliom_service.Ret.Non_ocaml
    ~id:(Eliom_service.Id.Path [])
    ~meth:(Eliom_service.Meth.Get Eliom_parameter.unit)
    ()

let preregister_service' =
  Eliom_service.create
    ~name:"preregister_service"
    ~ret:Eliom_service.Ret.Non_ocaml
    ~id:Eliom_service.Id.Global
    ~meth:
      (Eliom_service.Meth.Post
         (Eliom_parameter.unit,
          Eliom_parameter.string "email"))
    ()

let forgot_password_service =
  Eliom_service.create
    ~name:"lost_password"
    ~ret:Eliom_service.Ret.Non_ocaml
    ~id:Eliom_service.Id.Global
    ~meth:
      (Eliom_service.Meth.Post
         (Eliom_parameter.unit,
          Eliom_parameter.string "email"))
    ()

let set_personal_data_service' =
  Eliom_service.create
    ~name:"set_data"
    ~ret:Eliom_service.Ret.Non_ocaml
    ~id:Eliom_service.Id.Global
    ~meth:
      (Eliom_service.Meth.Post
         (Eliom_parameter.unit,
          (string "firstname" ** string "lastname") **
          (string "password"  ** string "password2")))
    ()

let sign_up_service' =
  Eliom_service.create
    ~name:"sign_up"
    ~ret:Eliom_service.Ret.Non_ocaml
    ~id:Eliom_service.Id.Global
    ~meth:
      (Eliom_service.Meth.Post
         (Eliom_parameter.unit,
          Eliom_parameter.string "email"))
    ()

let connect_service =
  Eliom_service.create
    ~name:"connect"
    ~ret:Eliom_service.Ret.Non_ocaml
    ~id:Eliom_service.Id.Global
    ~meth:
      (Eliom_service.Meth.Post
         (Eliom_parameter.unit,
          ((string "username" ** string "password") **
           bool "keepmeloggedin")))
    ()

let disconnect_service =
  Eliom_service.create
    ~name:"disconnect"
    ~ret:Eliom_service.Ret.Non_ocaml
    ~id:Eliom_service.Id.Global
    ~meth:
      (Eliom_service.Meth.Post
         (Eliom_parameter.unit, Eliom_parameter.unit))
    ()

let activation_service =
  Eliom_service.create
    ~name:"activation"
    ~ret:Eliom_service.Ret.Non_ocaml
    ~id:Eliom_service.Id.Global
    ~meth:(Eliom_service.Meth.Get (Eliom_parameter.string "activationkey"))
    ()

let eba_github_service =
  Eliom_service.create_external
    ~prefix:"http://github.com"
    ~ret:Eliom_service.Ret.Non_ocaml
    ~path:["ocsigen"; "eliom-base-app"]
    ~meth:(Eliom_service.Meth.Get Eliom_parameter.unit)
    ()

let ocsigen_service =
  Eliom_service.create_external
    ~prefix:"http://ocsigen.org"
    ~ret:Eliom_service.Ret.Non_ocaml
    ~path:[]
    ~meth:(Eliom_service.Meth.Get Eliom_parameter.unit)
    ()

let set_password_service' =
  Eliom_service.create
    ~name:"set_password"
    ~ret:Eliom_service.Ret.Non_ocaml
    ~id:Eliom_service.Id.Global
    ~meth:
      (Eliom_service.Meth.Post
         (Eliom_parameter.unit,
          string "password" ** string "password2"))
    ()
]
