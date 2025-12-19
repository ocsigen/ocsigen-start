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

(** Server to client notifications.
    
    This module is a version of [Eliom_notif] that fixes the types [identity] of
    [Eliom_notif.S] to [Os_types.User.id option] ([option] so that users can be
    notified that are not logged in). It takes care of (de)initialisation so
    [init] and [deinit] need not be called anymore. Also it adds a specialised
    version of [unlisten_user].
*)

open Os_types

module type S = sig
  include Eliom_notif.S with type identity = User.id option

  val unlisten_user :
     ?sitedata:Eliom_common.sitedata
    -> userid:User.id
    -> key
    -> unit
  (** Make a user stop listening on data [key]. This function will work as
      expected without a value supplied for [sitedata] if called during a
      request or initialisation. Otherwise a value needs to be supplied. *)

  val notify : ?notfor:[`Me | `User of User.id] -> key -> server_notif -> unit
end

(** [ARG] is for making [Make].
    It is a simplified version of [Eliom_notif.ARG]. *)
module type ARG = sig
  type key
  type server_notif
  type client_notif

  val prepare : User.id option -> server_notif -> client_notif option
  val equal_key : key -> key -> bool
  val max_resource : int
  val max_identity_per_resource : int
end

(** see [Eliom_notif.Make] *)
module Make (A : ARG) :
  S
  with type key = A.key
   and type server_notif = A.server_notif
   and type client_notif = A.client_notif

(** [ARG_SIMPLE] is for making [Make_Simple].
    It is a simplified version of [Eliom_notif.ARG_SIMPLE] *)
module type ARG_SIMPLE = sig
  type key
  type notification
end

(** Use this functor in case messages are to be delivered only to clients
    connected to the current server, as is always the case in a single-server
    set-up.
*)
module Make_Simple (A : ARG_SIMPLE) :
  S
  with type key = A.key
   and type server_notif = A.notification
   and type client_notif = A.notification
