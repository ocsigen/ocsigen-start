open %%%MODULE_NAME%%%_db
open Eliom_content.Html5.F

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
    avatar : string option;
  } deriving (Json)
}}

(** Create a user of type [t] using db informations. *)
let create_user_from_db (uid, fn, ln, avatar) = {
  uid = uid;
  fn = fn;
  ln = ln;
  avatar = avatar;
}

{shared{
(** Getters functions. *)
let uid_of_user u = u.uid
let firstname_of_user u = u.fn
let lastname_of_user u = u.ln
let avatar_of_user u =
  match u.avatar with
    | None -> "%%%PROJECT_NAME%%%_default_avatar.jpg"
    | Some avatar -> avatar

let avatar_uri_of_avatar avatar =
  Eliom_content.Html5.F.make_uri
    ~service:(Eliom_service.static_dir ()) ["avatars"; avatar]

let avatar_uri_of_user user = avatar_uri_of_avatar (avatar_of_user user)
 }}
let email_of_user user = %%%MODULE_NAME%%%_db.User.email_of_uid user.uid

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

let empty = {
  uid = 0L;
  fn = "";
  ln = "";
  avatar = None;
}

(** Helper function which creates a new user and return it as
 * a record of type [t]. May raise [Already_exists] *)
let create' ?password ?avatar ~firstname ~lastname email =
  try_lwt
    lwt _ = %%%MODULE_NAME%%%_db.User.uid_of_email email in
    Lwt.fail Already_exists
  with No_such_resource ->
    lwt uid =
      %%%MODULE_NAME%%%_db.User.create
        ~firstname ~lastname ?password ?avatar email
    in
    lwt u = %%%MODULE_NAME%%%_db.User.user_of_uid uid in
    Lwt.return (create_user_from_db u)

(* Overwrites the function [update] of [%%%MODULE_NAME%%%_db.User]
   to reset the cache *)
let update ?password ?avatar ~firstname ~lastname uid =
  lwt () = %%%MODULE_NAME%%%_db.User.update ?password ?avatar ~firstname ~lastname uid in
  MCache.reset uid;
  Lwt.return ()

let update' ?password t =
  update ?password ?avatar:t.avatar ~firstname:t.fn ~lastname:t.ln t.uid

let get_users ?pattern () =
  lwt users = %%%MODULE_NAME%%%_db.User.get_users ?pattern () in
  Lwt.return (List.map create_user_from_db users)
