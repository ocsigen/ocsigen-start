(** abstract type which correspond to a group.
  * a user belongs to one or more groups, each
  * group grants him some special rights (e.g:
  * beta-user, admin or whatever. *)
{shared{
  type t deriving (Json)
}}

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

val all : unit -> t list Lwt.t

{shared{
  (** returns the name of a t type (string) *)
  val name_of : t -> string

  (** returns the description of a t type if exists (string option) *)
  val desc_of : t -> string option
}}

(** default group needed by OL *)
val admin : t Lwt.t
