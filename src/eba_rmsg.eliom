module type TError = sig
  type t = private [> Eba_types.error_t ]

  val push : t -> unit
  val has : (t -> bool) -> bool
  val get : (t -> 'a option) -> 'a

  val iter : (t -> unit Lwt.t) -> unit Lwt.t
  val to_list : unit -> t list
end

module type TNotice = sig
  type t = private [> Eba_types.notice_t ]

  val push : t -> unit
  val has : (t -> bool) -> bool
  val get : (t -> 'a option) -> 'a

  val iter : (t -> unit Lwt.t) -> unit Lwt.t
  val to_list : unit -> t list
end

module type T = sig
  module Error : TError
  module Notice : TNotice
end

module type MT = sig
  type error_t = private [> Eba_types.error_t ]
  type notice_t = private [> Eba_types.notice_t ]
end

module Make(M : MT) : T = struct
  module Error = Eba_tools.Rmsg_f.Make(struct type t = M.error_t end)
  module Notice = Eba_tools.Rmsg_f.Make(struct type t = M.notice_t end)
end
