module type T = sig
  module Make : functor
    (M : sig type t end) -> sig
    type t

    val push : t -> unit
    val to_list : unit -> t list
  end
end

module Make(M : sig type t end) = struct
  type t = M.t

  let rmsgs : t list Eliom_reference.Volatile.eref =
    Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope []

  let to_list () =
    Eliom_reference.Volatile.get rmsgs

  let push (rmsg : t) =
    Eliom_reference.Volatile.set
      rmsgs (rmsg::(Eliom_reference.Volatile.get rmsgs))

end
