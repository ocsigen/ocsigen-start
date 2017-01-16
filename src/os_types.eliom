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

(** Data types

    This module defines types used in ocsigen-start in multiple files. It
    gives a more readable interface (for example by using [Os_types.User.id]
    instead of [int64]). Put all most used types in this file avoids to have
    dependencies between different modules for only one type.
 **)


[%%shared.start]

module User = struct
  (** Type representing a user ID *)
  type id = int64 [@@deriving json]

  (** Type representing a user. See <<a_api | module Os_user >>. *)
  type t = {
      userid : id;
      fn : string;
      ln : string;
      avatar : string option;
      language : string option;
    } [@@deriving json]
end

module Action_link_key = struct
  (** Action links *)
  type info = {
    userid        : User.id;
    email         : string;
    validity      : int64;
    autoconnect   : bool;
    action        : [ `AccountActivation | `PasswordReset | `Custom of string ];
    data          : string;
  }
end

module Group = struct
  (** Type representing a group ID *)
  type id = int64 [@@deriving json]

  (** Type representing a group. See <<a_api | module Os_group >> *)
  type t = {
    id    : id;
    name  : string;
    desc  : string option;
  }
end
