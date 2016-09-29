(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright (C) Université Paris Diderot, CNRS, INRIA, Be Sport.
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
]

let%server main_service =
  Eliom_service.create
    ~path:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

let%server preregister_service =
  Eliom_service.create
    ~name:"preregister_service"
    ~path:Eliom_service.No_path
    ~meth:
      (Eliom_service.Post
         (Eliom_parameter.unit,
          Eliom_parameter.string "email"))
    ()

let%server forgot_password_service =
  Eliom_service.create
    ~name:"lost_password"
    ~path:Eliom_service.No_path
    ~meth:
      (Eliom_service.Post
         (Eliom_parameter.unit,
          Eliom_parameter.string "email"))
    ()

let%server set_personal_data_service =
  Eliom_service.create
    ~name:"set_data"
    ~path:Eliom_service.No_path
    ~meth:
      (Eliom_service.Post
         (Eliom_parameter.unit,
          (string "firstname" ** string "lastname") **
          (string "password"  ** string "password2")))
    ()

let%server sign_up_service =
  Eliom_service.create
    ~name:"sign_up"
    ~path:Eliom_service.No_path
    ~meth:
      (Eliom_service.Post
         (Eliom_parameter.unit,
          Eliom_parameter.string "email"))
    ()

let%server connect_service =
  Eliom_service.create
    ~name:"connect"
    ~path:Eliom_service.No_path
    ~meth:
      (Eliom_service.Post
         (Eliom_parameter.unit,
          ((string "username" ** string "password") **
           bool "keepmeloggedin")))
    ()

let%server disconnect_service =
  Eliom_service.create
    ~name:"disconnect"
    ~path:Eliom_service.No_path
    ~meth:
      (Eliom_service.Post
         (Eliom_parameter.unit, Eliom_parameter.unit))
    ()

let%server action_link_service =
  Eliom_service.create
    ~name:"action_link"
    ~path:Eliom_service.No_path
    ~meth:(Eliom_service.Get (Eliom_parameter.string "actionkey"))
    ()

let%server set_password_service =
  Eliom_service.create
    ~name:"set_password"
    ~path:Eliom_service.No_path
    ~meth:
      (Eliom_service.Post
         (Eliom_parameter.unit,
          string "password" ** string "password2"))
    ()

let%server add_email_service = Eliom_service.create
  ~name:"add_email"
  ~path:Eliom_service.No_path
  ~meth:(Eliom_service.Post (
    Eliom_parameter.unit,
    Eliom_parameter.string "email"
  )) ()

let%client main_service = ~%main_service
let%client preregister_service = ~%preregister_service
let%client forgot_password_service = ~%forgot_password_service
let%client set_personal_data_service = ~%set_personal_data_service
let%client sign_up_service = ~%sign_up_service
let%client connect_service = ~%connect_service
let%client disconnect_service = ~%disconnect_service
let%client action_link_service = ~%action_link_service
let%client set_password_service = ~%set_password_service
let%client add_email_service = ~%add_email_service
