exception Already_exists
exception No_such_user

(* -----------------------------------------------------------------
 *
 * If you want to expand your user informations:
 *
 * You have to:
   *
 *   - expand the type [t] and adapt the function to create it
 *     [create_user_from_db].
 *
 *   - adapt the queries in the module [Foobar_db.User]
 *
 * *)

(** The type which represents a user. *)
type t = {
  uid : int64;
  fn : string;
  ln : string;
}

val uid_of_user : t -> int64
val firstname_of_user : t -> string
val lastname_of_user : t -> string

(** Returns true if the firstname and the lastname of [t] has not
  * been completed yet. *)
val is_complete : t -> bool

val add_activationkey : act_key:string -> int64 -> unit Lwt.t
val verify_password : email:string -> password:string -> int64 Lwt.t

val user_of_uid : int64 -> t Lwt.t

val uid_of_activationkey : string -> int64 Lwt.t
(** Retrieve an uid from an activation key. May raise [No_such_resource] if
  * the activation key is not found (or outdated). *)
val uid_of_email : string -> int64 Lwt.t

(** Create a new user and returns his uid. *)
val create :
  ?password:string -> firstname:string -> lastname:string -> string -> int64 Lwt.t
(** Same as above, but instead of returning the uid, it returns a user of type
  * [t] *)
val create' :
  ?password:string -> firstname:string -> lastname:string -> string -> t Lwt.t

(** Update the informations of a user. *)
val update :
  ?password:string -> firstname:string -> lastname:string -> int64 -> unit Lwt.t
(** Another version of [update] using a type [t] instead of labels. *)
val update' : ?password:string -> t -> unit Lwt.t
