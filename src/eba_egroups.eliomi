module type T = sig
  (** Abstract type which correspond to a egroup.
    * a user belongs to one or more egroups. *)
  type t = Eba_types.Egroups.t

  (** Creates the egroup in the database if it does
    * not exist, or returns its id as an abstract value *)
  val create : ?description:string -> string -> t Lwt.t

  (** Return the egroup if it exists as an [(Some t) Lwt.t], otherwise
    * it returns None *)
  val get : string -> t option Lwt.t

  (** Returns a list of all the created egroups *)
  val all : unit -> t list Lwt.t

  (** Add an email to a egroup *)
  val add_email : email:string -> egroup:t -> unit Lwt.t

  (** Remove a email from a egroup *)
  val remove_email : email:string -> egroup:t -> unit Lwt.t

  (** Returns [true] if the user belongs to the egroup, otherwise, return [false] *)
  val in_egroup : email:string -> egroup:t -> bool Lwt.t

  (** Retrieve [n] emails in the given [egroup]. *)
  val get_emails_in : egroup:t -> n:int -> string list Lwt.t

  (** Returns the id of a t type (int64) *)
  val id_of_egroup : t -> int64

  (** Returns the name of a t type (string) *)
  val name_of_egroup : t -> string

  (** Returns the description of a t type if exists (string option) *)
  val desc_of_egroup : t -> string option

  (** Default egroup needed by EBA *)
  val preregister : t
end

module Make : functor (M : sig module Database : Eba_db.T end) -> T
