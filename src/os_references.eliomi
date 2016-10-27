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

(** This module defines some Eliom references. *)

[%%server.start]

(** Set to [true] if an action link key has been already created and sent to the
    user email, else [false]. Default is [false]. *)
val action_link_key_created : bool Eliom_reference.Volatile.eref

(** [((firstname, lastname), (password, password_confirmation)) option]
    This reference is used to remember information about the user during a
    request when something went wrong (for example in a form when the password
    and password confirmation are not the same).
    If the value is [None], no user data has been set.
    Default is [None].
 *)
val wrong_pdata
  : ((string * string) * (string * string)) option Eliom_reference.Volatile.eref

(** Reference used to remember if a wrong password has been already typed. *)
val wrong_password : bool Eliom_reference.Volatile.eref

(** Reference used to remember if the account is activated. *)
val account_not_activated : bool Eliom_reference.Volatile.eref

(** Reference used to remember if the user already exists. *)
val user_already_exists : bool Eliom_reference.Volatile.eref

(** Reference used to remember if the user exists. *)
val user_does_not_exist : bool Eliom_reference.Volatile.eref

(** Reference used to remeber if the user is already preregistered. *)
val user_already_preregistered : bool Eliom_reference.Volatile.eref

(** Reference used to remeber if an action link key is outdated. *)
val action_link_key_outdated : bool Eliom_reference.Volatile.eref
