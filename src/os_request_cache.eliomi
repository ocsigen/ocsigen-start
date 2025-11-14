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

(** Caching request data to avoid doing the same computation several times
    during the same request. *)

module type Cache_sig = sig
  type key
  (** The type of the key *)

  type value
  (** The type of the value *)

  val has : key -> bool
  (** Returns [true] if the key has been stored into the cache. *)

  val set : key -> value -> unit
  (** Set the corresponding [value] for a key. *)

  val reset : key -> unit
  (** Remove a [value] for the given key. *)

  val get : key -> value
  (** Get the value corresponding to the given key. *)
end

(** Functor which creates a module {!Cache_sig}. *)
module Make : functor
    (M : sig
       type key
       (** The type of your key. *)

       type value
       (** The type of the stored value. *)

       val compare : key -> key -> int
       (** The function used to compare keys. *)

       val get : key -> value
       (** This function is called when the value corresponding to a key
         is not yet stored into the cache. *)
     end)
    -> Cache_sig with type key = M.key and type value = M.value
