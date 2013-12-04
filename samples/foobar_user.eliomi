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

{shared{
  (** The type which represents a user. *)
  type t = {
    uid : int64;
    fn : string;
    ln : string;
    avatar : string option;
  } deriving (Json)
}}


val uid_of_user : t -> int64
val firstname_of_user : t -> string
val lastname_of_user : t -> string
val avatar_of_user : t -> string
val avatar_uri_of_avatar : string -> Eliom_content_core.Xml.uri
val avatar_uri_of_user : t -> Eliom_content_core.Xml.uri

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
(** Retrieve the main e-mail of the corresponding uid. *)
val email_of_uid : int64 -> string Lwt.t

(** Get users who match the [pattern] (useful for completion) *)
val get_users : ?pattern:string -> unit -> t list Lwt.t

(** Create a new user and returns his uid. *)
val create :
  ?password:string -> ?avatar:string -> firstname:string -> lastname:string -> string -> int64 Lwt.t
(** Same as above, but instead of returning the uid, it returns a user of type
  * [t] *)
val create' :
  ?password:string -> ?avatar:string -> firstname:string -> lastname:string -> string -> t Lwt.t

(** Update the informations of a user. *)
val update :
  ?password:string -> ?avatar:string -> firstname:string -> lastname:string -> int64 -> unit Lwt.t
(** Another version of [update] using a type [t] instead of labels. *)
val update' : ?password:string -> t -> unit Lwt.t

(** Check wether or not a user exists *)
val is_registered : string -> bool Lwt.t

(** Check wether or not a user exists. *)
val is_preregistered : string -> bool Lwt.t

(** Add an email into the preregister collections. *)
val add_preregister : string -> unit Lwt.t

(** Rempve an email from the preregister collections. *)
val remove_preregister : string -> unit Lwt.t

(** Get [limit] (default: 10) emails from the preregister collections. *)
val all : ?limit:int64 -> unit -> string list Lwt.t
