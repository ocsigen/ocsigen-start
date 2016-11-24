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
    [Eliom_notif.S] to [Os_types.User.id option]. Also it adds the feature
    [unlisten_user].
*)

module type S = sig
  include Eliom_notif.S
    with type identity = Os_types.User.id option
  (** Make a user stop listening on data [key]
      TODO: document sitedata *)
  val unlisten_user :
    ?sitedata:Eliom_common.sitedata -> userid:Os_types.User.id -> key -> unit
end

(** [MAKE] is for making [Make] *)
module type MAKE = sig
  (** see [S.key] *)
  type key
  (** see [S.server_notif] *)
  type server_notif
  (** see [S.client_notif] *)
  type client_notif
	(** see [Eliom_notif.MAKE.prepare] *)
  val prepare : Os_types.User.id option -> server_notif -> client_notif option Lwt.t
	(** see [Eliom_notif.MAKE.equal_key] *)
  val equal_key : key -> key -> bool
end

(** see [Eliom_notif.Make] *)
module Make (A : MAKE) : S
  with type key = A.key
   and type server_notif = A.server_notif
   and type client_notif = A.client_notif

(** [SIMPLE] is for making [Simple] *)
module type SIMPLE = sig
  (** see [S.key] *)
  type key
  (** see [S.notification] *)
  type notification
	(** see [Eliom_notif.MAKE.equal_key] *)
  val equal_key : key -> key -> bool
end

(** Use this functor in case messages are to be delivered only to clients
    connected to the current server, as is always the case in a single-server
    set-up.
*)
module Simple (A : SIMPLE) : S
  with type key = A.key
   and type server_notif = A.notification
   and type client_notif = A.notification
