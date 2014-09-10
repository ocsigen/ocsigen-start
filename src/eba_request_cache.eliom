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

module type Cache_sig = sig
  type key
  type value

  val has : key -> bool
  val set : key -> value -> unit

  val reset : key -> unit
  val get : key -> value Lwt.t
  val wrap_function : key -> (unit -> 'a Lwt.t) -> 'a Lwt.t
end
module type Cache_f = sig
  module Make : functor
    (M : sig
       type key
       type value

       val compare : key -> key -> int
       val get : key -> value Lwt.t
     end) -> Cache_sig with type key = M.key and type value = M.value
end

module Make(M : sig
  type key
  type value

  val compare : key -> key -> int
  val get : key -> value Lwt.t
end) = struct
  type key = M.key
  type value = M.value

  (* we use an associative map to store the data *)
  module MMap = Map.Make(struct type t = M.key let compare = M.compare end)

  (* we use an eliom reference with the restrictive request scope, which is
   * sufficient and pretty safe (SECURITY), this permit to work on valid
   * data during the request *)
  let cache =
    Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope MMap.empty

  let has k =
    let table = Eliom_reference.Volatile.get cache in
    try
      ignore (MMap.find k table);
      true
    with
      | Not_found -> false

  let set k v =
    let table = Eliom_reference.Volatile.get cache in
    Eliom_reference.Volatile.set cache (MMap.add k v table)

  let reset (k : M.key) =
    let table = Eliom_reference.Volatile.get cache in
    Eliom_reference.Volatile.set cache (MMap.remove k table)

  let get (k : M.key) =
    let table = Eliom_reference.Volatile.get cache in
    try Lwt.return (MMap.find k table)
    with
      | Not_found ->
          try_lwt
            lwt ret = M.get k in
            Eliom_reference.Volatile.set cache (MMap.add k ret table);
            Lwt.return ret
          with _ -> Lwt.fail Not_found


  let wrap_function (k : M.key) f =
    (* we call the user function and we will reset the data correponding
       to the key to be sure that we're going to use valid data with the
       cache *)
    lwt ret = f () in
    let () = reset k in
    Lwt.return ret

end
