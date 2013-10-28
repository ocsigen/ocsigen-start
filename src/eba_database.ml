module type Tuser = sig
  type ext_t

  val new_user : ?password:string -> email:string -> ext_t -> int64 Lwt.t

  val update : ?password:string -> ext_t Eba_types.User.ext_t -> unit Lwt.t
  val attach_activationkey : act_key:string -> int64 -> unit Lwt.t
  val verify_password : string -> string -> int64 option Lwt.t

  val user_of_uid : int64 -> ext_t Eba_types.User.ext_t option Lwt.t
  val uid_of_email : string -> int64 option Lwt.t
  val uid_of_activationkey : string -> int64 option Lwt.t
end

module type Tgroups = sig
  val new_group : ?description:string -> string -> unit Lwt.t
  val get_group : string -> Eba_types.Groups.t option Lwt.t

  val add_user_in_group : group:Eba_types.Groups.t -> userid:int64 -> unit Lwt.t
  val remove_user_in_group : group:Eba_types.Groups.t -> userid:int64 -> unit Lwt.t
  val in_group : group:Eba_types.Groups.t -> userid:int64 -> bool Lwt.t

  val all : unit -> Eba_types.Groups.t list Lwt.t
end

module type T = sig
  module User : Tuser
  module Groups : Tgroups
end
