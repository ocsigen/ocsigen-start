(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
 *
 * Copyright (C) 2014
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

(** Tips for new users and new features. *)

(** Display tips for beginners in pages.
    Tips can be inserted in page using function [display],
    that may be called anywhere during the generation of a page.
    The tip will be actually sent and displayed on client side
    only if the user has not already seen it.

    - [~name] is a unique name you must choose for your tip
    - [?arrow] is the position of the arrow if you want one
    - [?top], [?bottom], [?left], [?right], [?width], [?right] correspond
    to the eponymous CSS properties.

*)

val display :
  ?arrow: [< `left of int
          | `right of int
          | `top of int
          | `bottom of int ] ->
  ?top:int ->
  ?left:int ->
  ?right:int ->
  ?bottom:int ->
  ?height:int ->
  ?width:int ->
  ?parent_node:'a Eliom_content.Html5.elt ->
  name:string ->
  content: Html5_types.div_content Eliom_content.Html5.elt list ->
  unit ->
  unit Lwt.t



(** Call this function to reset tips for one user.
    The parameter is the user id.
    Tips will be shown again from the beginning.
*)
val reset_tips : int64 -> unit -> unit -> unit Lwt.t

(** A non-attached service that will reset tips.
    Call it with [Eliom_client.exit_to] to restart the application and
    see tips again. *)
val reset_tips_service :
  (unit, unit, [< Eliom_service.service_method > `Post ],
   [< Eliom_service.attached > `Nonattached ],
   [< Eliom_service.service_kind > `NonattachedCoservice ],
   [ `WithoutSuffix ], unit, unit,
   [< Eliom_service.registrable > `Registrable ],
   [> Eliom_service.http_service ])
         Eliom_service.service


{client{
(** Call this function to reset tips for current users.
    Tips will be shown again from the beginning.
*)
val reset_tips : unit -> unit Lwt.t
}}
