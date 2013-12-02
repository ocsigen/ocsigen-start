exception No_such_group

(* -----------------------------------------------------------------
 *
 * The implementation of this module should be sufficient. Groups are
 * needed by EBA to allow or deny access to functions or pages.
 *
 * EBA uses only the type [t] of the module and the [in_group] function
 * to know if a userid belongs to a group.
 *
 * *)

(** The type of a group *)
type t = {
  id : int64;
  name : string;
  desc : string option;
}

val id_of_group : t -> int64
val name_of_group : t -> string
val desc_of_group : t -> string option

(** Helper function which creates a new group and return it as
  * a record of type [t]. *)
val create : ?description:string -> string -> t Lwt.t

(** Overwrite the function [get_group] of [%%%MODULE_NAME%%%_db.User] and use
  * the [get] function of the cache module. *)
val group_of_name : string -> t Lwt.t

(* -----------------------------------------------------------------
 *
 * All the followings functions are only helpers/wrappers around db
 * functions ones. They generally use the type [t] of the module
 * and get rid of the part of picking each field of the record [t].
 *
 * *)

val add_user_in_group : group:t -> userid:int64 -> unit Lwt.t
val remove_user_in_group : group:t -> userid:int64 -> unit Lwt.t
val in_group : group:t -> userid:int64 -> bool Lwt.t

(** Returns all the groups of the database. *)
val all : unit -> t list Lwt.t
