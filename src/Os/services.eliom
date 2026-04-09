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

(** This module defines services which are mostly used for actions like the
    signup process, to update user data, when a user forgot his password, etc.
    Some of them are used in forms defined in User_view.
    Predefined handlers for each service are defined in the module
    Handlers. *)

[%%server open Eliom.Parameter]

(** The main service. *)
let%server main_service =
  Eliom.Service.create ~path:(Eliom.Service.Path [])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

(** A POST service to preregister a user. By default, an email is
    enough. *)
let%server preregister_service =
  Eliom.Service.create ~name:"preregister_service" ~path:Eliom.Service.No_path
    ~meth:
      (Eliom.Service.Post (Eliom.Parameter.unit, Eliom.Parameter.string "email"))
    ()

(** A POST service when the user forgot his password.
    See {!Handlers.forgot_password_handler for a default handler. *)
let%server forgot_password_service =
  Eliom.Service.create ~name:"lost_password" ~path:Eliom.Service.No_path
    ~meth:
      (Eliom.Service.Post (Eliom.Parameter.unit, Eliom.Parameter.string "email"))
    ()

(** A POST service to update the basic user data like first name, last name and
    password.
    See {!Handlers.set_personal_data_handler for a default handler. *)
let%server set_personal_data_service =
  Eliom.Service.create ~name:"set_data" ~path:Eliom.Service.No_path
    ~meth:
      (Eliom.Service.Post
         ( Eliom.Parameter.unit
         , (string "firstname" ** string "lastname")
           ** string "password" ** string "password2" ))
    ()

(** A POST service to sign up with only an email address.
    See {!Handlers.sign_up_handler for a default handler. *)
let%server sign_up_service =
  Eliom.Service.create ~name:"sign_up" ~path:Eliom.Service.No_path
    ~meth:
      (Eliom.Service.Post (Eliom.Parameter.unit, Eliom.Parameter.string "email"))
    ()

(** A POST service to connect a user with username and password.
    See {!Handlers.connect_handler for a default handler. *)
let%server connect_service =
  Eliom.Service.create ~name:"connect" ~path:Eliom.Service.No_path
    ~meth:
      (Eliom.Service.Post
         ( Eliom.Parameter.unit
         , (string "username" ** string "password") ** bool "keepmeloggedin" ))
    ()

(** A POST service to disconnect the current user.
    See {!Handlers.disconnect_handler} for a default handler. *)
let%server disconnect_service =
  Eliom.Service.create ~name:"disconnect" ~path:Eliom.Service.No_path
    ~meth:(Eliom.Service.Post (Eliom.Parameter.unit, Eliom.Parameter.unit))
    ()

(** A GET service for action link keys.
    See {!Handlers.action_link_handler} for a default handler and
    {!Db.action_link_table} for more information about the action
    process. *)
let%server action_link_service =
  Eliom.Service.create ~name:"action_link" ~path:Eliom.Service.No_path
    ~meth:(Eliom.Service.Get (Eliom.Parameter.string "actionkey"))
    ()

(** A POST service to update the password. An update password action is
    associated with the confirmation password.
    See {!Handlers.set_password_handler} for a default handler. *)
let%server set_password_service =
  Eliom.Service.create ~name:"set_password" ~path:Eliom.Service.No_path
    ~meth:
      (Eliom.Service.Post
         (Eliom.Parameter.unit, string "password" ** string "password2"))
    ()

(** A POST service to add an email to a user.
    See {!Handlers.add_email_handler} for a default handler. *)
let%server add_email_service =
  Eliom.Service.create ~name:"add_email" ~path:Eliom.Service.No_path
    ~meth:
      (Eliom.Service.Post (Eliom.Parameter.unit, Eliom.Parameter.string "email"))
    ()

let%server update_language_service =
  Eliom.Service.create ~name:"update_language" ~path:Eliom.Service.No_path
    ~meth:
      (Eliom.Service.Post
         (Eliom.Parameter.unit, Eliom.Parameter.string "language"))
    ()

let confirm_code_signup_service =
  Eliom.Service.create ~name:"confirm_code_signup" ~path:Eliom.Service.No_path
    ~meth:
      (Eliom.Service.Post
         ( unit
         , string "first_name" ** string "last_name" ** string "password"
           ** string "number" ))
    ()

let confirm_code_extra_service =
  Eliom.Service.create ~name:"confirm_code_extra" ~path:Eliom.Service.No_path
    ~meth:(Eliom.Service.Post (unit, string "number"))
    ()

let confirm_code_recovery_service =
  Eliom.Service.create ~name:"confirm_code_recovery" ~path:Eliom.Service.No_path
    ~meth:(Eliom.Service.Post (unit, string "number"))
    ()

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
let%client update_language_service = ~%update_language_service
let%client confirm_code_signup_service = ~%confirm_code_signup_service
let%client confirm_code_extra_service = ~%confirm_code_extra_service
let%client confirm_code_recovery_service = ~%confirm_code_recovery_service

(* [Handlers.add_email_handler] needs access to the settings
   service, but the latter needs to be defined in the template. So we
   use the reference [settings_service_ref]. The template needs to
   call [set_settings_service]. *)
let%shared settings_service_ref = ref None
let%shared register_settings_service s = settings_service_ref := Some s
let%shared settings_service () = !settings_service_ref
let%shared confirm_code_remind_service = confirm_code_recovery_service
