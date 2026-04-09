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

[%%shared.start]
(** This module provides pre-defined services for connect, disconnect, sign up,
    add a new email, etc. Each service has a corresponding handler in
    {!Handlers}.
 *)

val main_service :
  ( unit
    , unit
    , Eliom.Service.get
    , Eliom.Service.att
    , Eliom.Service.non_co
    , Eliom.Service.non_ext
    , Eliom.Service.reg
    , [`WithoutSuffix]
    , unit
    , unit
    , Eliom.Service.non_ocaml )
    Eliom.Service.t
(** The main service. *)

val preregister_service :
  ( unit
    , string
    , Eliom.Service.post
    , Eliom.Service.non_att
    , Eliom.Service.co
    , Eliom.Service.non_ext
    , Eliom.Service.reg
    , [`WithoutSuffix]
    , unit
    , [`One of string] Eliom.Parameter.param_name
    , Eliom.Service.non_ocaml )
    Eliom.Service.t
(** A POST service to preregister a user. By default, an email is
    enough. *)

val forgot_password_service :
  ( unit
    , string
    , Eliom.Service.post
    , Eliom.Service.non_att
    , Eliom.Service.co
    , Eliom.Service.non_ext
    , Eliom.Service.reg
    , [`WithoutSuffix]
    , unit
    , [`One of string] Eliom.Parameter.param_name
    , Eliom.Service.non_ocaml )
    Eliom.Service.t
(** A POST service when the user forgot his password.
    See {!Handlers.forgot_password_handler} for a default handler.
 *)

val set_personal_data_service :
  ( unit
    , (string * string) * (string * string)
    , Eliom.Service.post
    , Eliom.Service.non_att
    , Eliom.Service.co
    , Eliom.Service.non_ext
    , Eliom.Service.reg
    , [`WithoutSuffix]
    , unit
    , ([`One of string] Eliom.Parameter.param_name
      * [`One of string] Eliom.Parameter.param_name)
      * ([`One of string] Eliom.Parameter.param_name
        * [`One of string] Eliom.Parameter.param_name)
    , Eliom.Service.non_ocaml )
    Eliom.Service.t
(** A POST service to update the basic user data like first name, last name and
    password.
    See {!Handlers.set_personal_data_handler'} for a default handler.
 *)

val sign_up_service :
  ( unit
    , string
    , Eliom.Service.post
    , Eliom.Service.non_att
    , Eliom.Service.co
    , Eliom.Service.non_ext
    , Eliom.Service.reg
    , [`WithoutSuffix]
    , unit
    , [`One of string] Eliom.Parameter.param_name
    , Eliom.Service.non_ocaml )
    Eliom.Service.t
(** A POST service to sign up with only an email address.
    See {!Handlers.sign_up_handler} for a default handler.
 *)

val connect_service :
  ( unit
    , (string * string) * bool
    , Eliom.Service.post
    , Eliom.Service.non_att
    , Eliom.Service.co
    , Eliom.Service.non_ext
    , Eliom.Service.reg
    , [`WithoutSuffix]
    , unit
    , ([`One of string] Eliom.Parameter.param_name
      * [`One of string] Eliom.Parameter.param_name)
      * [`One of bool] Eliom.Parameter.param_name
    , Eliom.Service.non_ocaml )
    Eliom.Service.t
(** A POST service to connect a user with username and password.
    See {!Handlers.connect_handler} for a default handler.
 *)

val disconnect_service :
  ( unit
    , unit
    , Eliom.Service.post
    , Eliom.Service.non_att
    , Eliom.Service.co
    , Eliom.Service.non_ext
    , Eliom.Service.reg
    , [`WithoutSuffix]
    , unit
    , unit
    , Eliom.Service.non_ocaml )
    Eliom.Service.t
(** A POST service to disconnect the current user.
    See {!Handlers.disconnect_handler} for a default handler.
 *)

val action_link_service :
  ( string
    , unit
    , Eliom.Service.get
    , Eliom.Service.non_att
    , Eliom.Service.co
    , Eliom.Service.non_ext
    , Eliom.Service.reg
    , [`WithoutSuffix]
    , [`One of string] Eliom.Parameter.param_name
    , unit
    , Eliom.Service.non_ocaml )
    Eliom.Service.t
(** A GET service for action link keys.
    See {!Handlers.action_link_handler} for a default handler and
    {!Db.action_link_table} for more information about the action
    process.
 *)

val set_password_service :
  ( unit
    , string * string
    , Eliom.Service.post
    , Eliom.Service.non_att
    , Eliom.Service.co
    , Eliom.Service.non_ext
    , Eliom.Service.reg
    , [`WithoutSuffix]
    , unit
    , [`One of string] Eliom.Parameter.param_name
      * [`One of string] Eliom.Parameter.param_name
    , Eliom.Service.non_ocaml )
    Eliom.Service.t
(** A POST service to update the password. An update password action is
    associated with the confirmation password.
    See {!Handlers.set_password_handler'} for a default handler.
 *)

val add_email_service :
  ( unit
    , string
    , Eliom.Service.post
    , Eliom.Service.non_att
    , Eliom.Service.co
    , Eliom.Service.non_ext
    , Eliom.Service.reg
    , [`WithoutSuffix]
    , unit
    , [`One of string] Eliom.Parameter.param_name
    , Eliom.Service.non_ocaml )
    Eliom.Service.t
(** A POST service to add an email to a user.
    See {!Handlers.add_email_handler} for a default handler.
 *)

val update_language_service :
  ( unit
    , string
    , Eliom.Service.post
    , Eliom.Service.non_att
    , Eliom.Service.co
    , Eliom.Service.non_ext
    , Eliom.Service.reg
    , [`WithoutSuffix]
    , unit
    , [`One of string] Eliom.Parameter.param_name
    , Eliom.Service.non_ocaml )
    Eliom.Service.t
(** A POST service to update the language of the current user.
     See {!Handlers.update_language_handler} for a default handler.
*)

val confirm_code_signup_service :
  ( unit
    , string * (string * (string * string))
    , Eliom.Service.post
    , Eliom.Service.non_att
    , Eliom.Service.co
    , Eliom.Service.non_ext
    , Eliom.Service.reg
    , [`WithoutSuffix]
    , unit
    , [`One of string] Eliom.Parameter.param_name
      * ([`One of string] Eliom.Parameter.param_name
        * ([`One of string] Eliom.Parameter.param_name
          * [`One of string] Eliom.Parameter.param_name))
    , Eliom.Service.non_ocaml )
    Eliom.Service.t
(** Confirm SMS activation code and (if valid) register new user. *)

val confirm_code_extra_service :
  ( unit
    , string
    , Eliom.Service.post
    , Eliom.Service.non_att
    , Eliom.Service.co
    , Eliom.Service.non_ext
    , Eliom.Service.reg
    , [`WithoutSuffix]
    , unit
    , [`One of string] Eliom.Parameter.param_name
    , Eliom.Service.non_ocaml )
    Eliom.Service.t
(** Confirm SMS activation code and (if valid) add new phone number to
    user's account. *)

val confirm_code_recovery_service :
  ( unit
    , string
    , Eliom.Service.post
    , Eliom.Service.non_att
    , Eliom.Service.co
    , Eliom.Service.non_ext
    , Eliom.Service.reg
    , [`WithoutSuffix]
    , unit
    , [`One of string] Eliom.Parameter.param_name
    , Eliom.Service.non_ocaml )
    Eliom.Service.t
(** Confirm SMS activation code and (if valid) allow the user to set a
    new password. *)

val confirm_code_remind_service :
  ( unit
    , string
    , Eliom.Service.post
    , Eliom.Service.non_att
    , Eliom.Service.co
    , Eliom.Service.non_ext
    , Eliom.Service.reg
    , [`WithoutSuffix]
    , unit
    , [`One of string] Eliom.Parameter.param_name
    , Eliom.Service.non_ocaml )
    Eliom.Service.t
(** Temporary alternate name for [confirm_code_recovery_handler] to
    facilite the transition. *)

val register_settings_service :
   ( unit
     , unit
     , Eliom.Service.get
     , Eliom.Service.att
     , Eliom.Service.non_co
     , Eliom.Service.non_ext
     , Eliom.Service.reg
     , [`WithoutSuffix]
     , unit
     , unit
     , Eliom.Service.non_ocaml )
     Eliom.Service.t
  -> unit
(** Register the settings service (defined in the app rather than in
    the OS lib) because we need to perform redirections to it. *)

(**/**)

val settings_service :
   unit
  -> ( unit
       , unit
       , Eliom.Service.get
       , Eliom.Service.att
       , Eliom.Service.non_co
       , Eliom.Service.non_ext
       , Eliom.Service.reg
       , [`WithoutSuffix]
       , unit
       , unit
       , Eliom.Service.non_ocaml )
       Eliom.Service.t
       option
