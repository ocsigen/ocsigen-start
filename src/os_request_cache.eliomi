(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
 *
 * Copyright (C) 2014
 *      Charly Chevalier
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


(** Caching request data to avoid doing the same computation several times
    during the same request. *)

module type Cache_sig = sig

  (** The type of the key *)
  type key

  (** The type of the value *)
  type value

  (** Returns [true] if the key has been stored into the cache. *)
  val has : key -> bool

  (** Set the corresponding [value] for a key. *)
  val set : key -> value -> unit

  (** Remove a [value] for the given key. *)
  val reset : key -> unit

  (** Get the value corresponding to the given key. *)
  val get : key -> value Lwt.t

end


module Make : functor
  (M : sig

     (** The type of your key. *)
     type key

     (** The type of the stored value. *)
     type value

     (** The function used to compare keys. *)
     val compare : key -> key -> int

     (** This function is called when the value corresponding to a key
         is not yet stored into the cache. *)
     val get : key -> value Lwt.t

   end) -> Cache_sig with type key = M.key and type value = M.value
