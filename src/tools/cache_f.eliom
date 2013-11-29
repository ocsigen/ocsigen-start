module Make(M : sig
  type key_t
  type value_t

  val compare : key_t -> key_t -> int
  val get : key_t -> value_t Lwt.t
end) = struct
  type key_t = M.key_t
  type value_t = M.value_t

  (* we use an associative map to store the data *)
  module MMap = Map.Make(struct type t = M.key_t let compare = M.compare end)

  (* we use an eliom reference with the restrictive request scope, which is
   * sufficient and pretty safe (SECURITY), this permit to work on valid
   * data during the request *)
  let cache =
    Eliom_reference.Volatile.eref
      ~scope:Eliom_common.request_scope
      MMap.empty

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

  let reset (k : M.key_t) =
    let table = Eliom_reference.Volatile.get cache in
    Eliom_reference.Volatile.set cache (MMap.remove k table)

  let get (k : M.key_t) =
    let table = Eliom_reference.Volatile.get cache in
    try Lwt.return (MMap.find k table)
    with
      | Not_found ->
          try_lwt
            lwt ret = M.get k in
            Eliom_reference.Volatile.set cache (MMap.add k ret table);
            Lwt.return ret
          with _ -> Lwt.fail Not_found


  let wrap_function (k : M.key_t) f =
    (* we call the user function and we will reset the data correponding
     * to the key to be sure that we're going to use valid data with the
     * cache *)
    lwt ret = f () in
    let () = reset k in
    Lwt.return ret

end
