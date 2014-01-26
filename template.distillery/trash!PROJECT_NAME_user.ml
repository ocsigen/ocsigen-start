open %%%MODULE_NAME%%%_db

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
 *   - adapt the queries in the module [%%%MODULE_NAME%%%_db.User]
 *
 * *)

{shared{
  (** The type which represents a user. *)
  type t = {
    uid : int64;
    fn : string;
    ln : string;
  } deriving (Json)
}}

(** Create a user of type [t] using db informations. *)
let create_user_from_db (uid, fn, ln) = {
  uid = uid;
  fn = fn;
  ln = ln;
}

(** Getters functions. *)
let uid_of_user u = u.uid
let firstname_of_user u = u.fn
let lastname_of_user u = u.ln

let is_complete u =
  not (u.fn = "" && u.ln = "")

include %%%MODULE_NAME%%%_db.User

(* Using cache tools to prevent multiple same database queries
 * during the request. *)
module MCache = Eba_tools.Cache_f.Make(
struct
  type key_t = int64
  type value_t = t

  let compare = compare
  let get key =
    try_lwt
      lwt g = %%%MODULE_NAME%%%_db.User.user_of_uid key in
      Eliom_lib.debug "reset value";
      Lwt.return (create_user_from_db g)
    with No_such_resource -> Lwt.fail No_such_user
end)

(** Overwrite the function [user_of_uid] of [%%%MODULE_NAME%%%_db.User] and use
  * the [get] function of the cache module. *)
let user_of_uid uid =
  lwt u = MCache.get uid in
  Eliom_lib.debug "fn[%s]" u.fn;
  Lwt.return u

(* -----------------------------------------------------------------
 *
 * All the followings functions are only helpers/wrappers around db
 * functions ones. They generally use the type [t] of the module
 * and get rid of the part of picking each field of the record [t].
 *
 * *)


(** Helper function which creates a new user and return it as
 * a record of type [t]. May raise [Already_exists] *)
let create' ?password ~firstname ~lastname email =
  try_lwt
    lwt _ = %%%MODULE_NAME%%%_db.User.uid_of_email email in
    Lwt.fail Already_exists
  with No_such_resource ->
    lwt uid = %%%MODULE_NAME%%%_db.User.create ~firstname ~lastname ?password email in
    lwt u = %%%MODULE_NAME%%%_db.User.user_of_uid uid in
    Lwt.return (create_user_from_db u)

(* Overwrite the function [update] of [%%%MODULE_NAME%%%_db.User] to reset the cache *)
let update ?password ~firstname ~lastname uid =
  lwt () = %%%MODULE_NAME%%%_db.User.update ?password ~firstname ~lastname uid in
  MCache.reset uid;
  Lwt.return ()

let update' ?password t =
  update ?password ~firstname:t.fn ~lastname:t.ln t.uid
