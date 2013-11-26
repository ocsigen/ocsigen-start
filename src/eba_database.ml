module type Tgroups = sig
  val new_group : ?description:string -> string -> unit Lwt.t
  val get_group : string -> Eba_types.Groups.t option Lwt.t

  val add_user_in_group : group:Eba_types.Groups.t -> userid:int64 -> unit Lwt.t
  val remove_user_in_group : group:Eba_types.Groups.t -> userid:int64 -> unit Lwt.t
  val in_group : group:Eba_types.Groups.t -> userid:int64 -> bool Lwt.t

  val all : unit -> Eba_types.Groups.t list Lwt.t
end

module type T = sig
  module Groups : Tgroups
end
