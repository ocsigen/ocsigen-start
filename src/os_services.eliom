(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
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

[%%server
open Eliom_parameter

let main_service =
  Eliom_service.create
    ~id:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

let preregister_service' =
  Eliom_service.create
    ~name:"preregister_service"
    ~id:Eliom_service.Global
    ~meth:
      (Eliom_service.Post
         (Eliom_parameter.unit,
          Eliom_parameter.string "email"))
    ()

let forgot_password_service =
  Eliom_service.create
    ~name:"lost_password"
    ~id:Eliom_service.Global
    ~meth:
      (Eliom_service.Post
         (Eliom_parameter.unit,
          Eliom_parameter.string "email"))
    ()

let set_personal_data_service' =
  Eliom_service.create
    ~name:"set_data"
    ~id:Eliom_service.Global
    ~meth:
      (Eliom_service.Post
         (Eliom_parameter.unit,
          (string "firstname" ** string "lastname") **
          (string "password"  ** string "password2")))
    ()

let sign_up_service' =
  Eliom_service.create
    ~name:"sign_up"
    ~id:Eliom_service.Global
    ~meth:
      (Eliom_service.Post
         (Eliom_parameter.unit,
          Eliom_parameter.string "email"))
    ()

let connect_service =
  Eliom_service.create
    ~name:"connect"
    ~id:Eliom_service.Global
    ~meth:
      (Eliom_service.Post
         (Eliom_parameter.unit,
          ((string "username" ** string "password") **
           bool "keepmeloggedin")))
    ()

let disconnect_service =
  Eliom_service.create
    ~name:"disconnect"
    ~id:Eliom_service.Global
    ~meth:
      (Eliom_service.Post
         (Eliom_parameter.unit, Eliom_parameter.unit))
    ()

let action_link_service =
  Eliom_service.create
    ~name:"action_link"
    ~id:Eliom_service.Global
    ~meth:(Eliom_service.Get (Eliom_parameter.string "actionkey"))
    ()

let os_github_service =
  Eliom_service.create
    ~id:
      (Eliom_service.External
         ("http://github.com",
          ["ocsigen"; "ocsigen-start"]))
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

let ocsigen_service =
  Eliom_service.create
    ~id:(Eliom_service.External ("http://ocsigen.org", []))
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

let set_password_service' =
  Eliom_service.create
    ~name:"set_password"
    ~id:Eliom_service.Global
    ~meth:
      (Eliom_service.Post
         (Eliom_parameter.unit,
          string "password" ** string "password2"))
    ()

let add_email_service = Eliom_service.create
  ~name:"add_email"
  ~id:Eliom_service.Global
  ~meth:(Eliom_service.Post (
    Eliom_parameter.unit,
    Eliom_parameter.string "email"
  )) ()

]

[%%client

let main_service = ~%main_service
let preregister_service' = ~%preregister_service'
let forgot_password_service = ~%forgot_password_service
let set_personal_data_service' = ~%set_personal_data_service'
let sign_up_service' = ~%sign_up_service'
let connect_service = ~%connect_service
let disconnect_service = ~%disconnect_service
let action_link_service = ~%action_link_service
let os_github_service = ~%os_github_service
let ocsigen_service = ~%ocsigen_service
let set_password_service' = ~%set_password_service'
let add_email_service = ~%add_email_service

]
