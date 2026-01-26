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

module type Cache_sig = sig
  type key
  type value

  val has : key -> bool
  val set : key -> value -> unit
  val reset : key -> unit
  val get : key -> value
end

module Make (M : sig
    type key
    type value

    val compare : key -> key -> int
    val get : key -> value
  end) =
struct
  type key = M.key
  type value = M.value

  (* we use an associative map to store the data *)
  module MMap = Map.Make (struct
      type t = M.key

      let compare = M.compare
    end)

  (* we use an eliom reference with the restrictive request scope, which is
     sufficient and safe (SECURITY) *)
  let cache =
    Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope MMap.empty

  let has k =
    Eliom_common.get_sp_option () <> None
    && MMap.mem k (Eliom_reference.Volatile.get cache)

  let set k v =
    if Eliom_common.get_sp_option () <> None
    then
      let table = Eliom_reference.Volatile.get cache in
      Eliom_reference.Volatile.set cache (MMap.add k v table)

  let reset (k : M.key) =
    if Eliom_common.get_sp_option () <> None
    then
      let table = Eliom_reference.Volatile.get cache in
      Eliom_reference.Volatile.set cache (MMap.remove k table)

  let get (k : M.key) =
    if Eliom_common.get_sp_option () = None
    then M.get k (* Not during a request. No cache. *)
    else
      let table = Eliom_reference.Volatile.get cache in
      try MMap.find k table
      with Not_found ->
        let ret = M.get k in
        Eliom_reference.Volatile.set cache (MMap.add k ret table);
        ret
end
