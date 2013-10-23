(** abstract type which correspond to a group.
  * a user belongs to one or more groups, each
  * group grants him some special rights (e.g:
  * beta-user, admin or whatever. *)

module type T = sig
  type t = Eba_types.Groups.t

  val create : ?description:string -> string -> t Lwt.t
  val get : string -> t option Lwt.t

  val add_user : userid:int64 -> group:t -> unit Lwt.t
  val remove_user : userid:int64 -> group:t -> unit Lwt.t
  val in_group : userid:int64 -> group:t -> bool Lwt.t

  val all : unit -> t list Lwt.t

  val admin : t
end

module Make : functor (M : sig module Database : Eba_db.T end) -> sig

  type t = Eba_types.Groups.t

  (** creates the group in the database if it does
    * not exist, or returns its id as an abstract value *)
  val create : ?description:string -> string -> t Lwt.t

  (** return the group if it exists as an [(Some t) Lwt.t], otherwise
    * it returns None *)
  val get : string -> t option Lwt.t

  (** add a user to a group *)
  val add_user : userid:int64 -> group:t -> unit Lwt.t

  (** remove a user from a group *)
  val remove_user : userid:int64 -> group:t -> unit Lwt.t

  (** returns [true] if the user belongs to the group, otherwise, return [false] *)
  val in_group : userid:int64 -> group:t -> bool Lwt.t

  (** returns a list of all the created groups *)
  val all : unit -> t list Lwt.t

  (** returns the id of a t type (int64) *)
  val id_of_group : t -> int64

  (** returns the name of a t type (string) *)
  val name_of_group : t -> string

  (** returns the description of a t type if exists (string option) *)
  val desc_of_group : t -> string option

  (** default group needed by EBA *)
  val admin : t
end
