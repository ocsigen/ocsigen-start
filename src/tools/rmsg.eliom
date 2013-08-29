module type T = sig
  type t

  val push : t -> unit
  val has : (t -> bool) -> bool
  val get : (t -> 'a option) -> 'a

  val iter : (t -> unit Lwt.t) -> unit Lwt.t
end

module Make(M : sig type t end) = struct

  type t = M.t

  let rmsgs : t list Eliom_reference.Volatile.eref =
    Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope []

  let push (rmsg : t) =
    Eliom_reference.Volatile.set
      rmsgs (rmsg::(Eliom_reference.Volatile.get rmsgs))

  let has f =
    List.exists f (Eliom_reference.Volatile.get rmsgs)

  let get f =
    let rec aux rl = function
      | [] -> raise Not_found
      | hd::tl ->
          match f hd with
            | None -> aux (hd::rl) tl
            | Some ret ->
                Eliom_reference.Volatile.set rmsgs (rl @ tl);
                ret
    in aux [] (Eliom_reference.Volatile.get rmsgs)

  let iter f =
    Lwt_list.iter_s f (Eliom_reference.Volatile.get rmsgs)

end
