(* This file is part of Ocsigen-start.
   Feel free to use it, modify it according to your needs,
   and redistribute it as you wish. *)

open Eliom_content.Html.F

exception Already_exists of int64
exception No_such_user

[%%shared
  (** The type which represents a user. *)
  type t = {
    userid : int64;
    fn : string;
    ln : string;
    avatar : string option;
  } [@@deriving json]
]

(** Create a user of type [t] using db informations. *)
let create_user_from_db0 (userid, fn, ln, avatar, pwdset) =
  {
    userid = userid;
    fn = fn;
    ln = ln;
    avatar = avatar;
  },
  pwdset

let create_user_from_db d = fst (create_user_from_db0 d)

[%%shared
(** Getters functions. *)
let userid_of_user u = u.userid
let firstname_of_user u = u.fn
let lastname_of_user u = u.ln
let avatar_of_user u = u.avatar

let avatar_uri_of_avatar ?absolute_path avatar =
  Eliom_content.Html.F.make_uri ?absolute_path
    ~service:(Eliom_service.static_dir ()) ["avatars"; avatar]

let avatar_uri_of_user ?absolute_path user =
  Eliom_lib.Option.map
    (avatar_uri_of_avatar ?absolute_path) (avatar_of_user user)

let fullname_of_user user = String.concat " " [user.fn; user.ln]

let is_complete u = not (u.fn = "" || u.ln = "")

]
let emails_of_user user = Os_db.User.emails_of_userid user.userid
let email_of_user user = Os_db.User.email_of_userid user.userid


include Os_db.User


(* Using cache tools to prevent multiple same database queries
   during the request. *)
module MCache = Os_request_cache.Make(
struct
  type key = int64
  type value = t * bool

  let compare = compare
  let get key =
    try%lwt
      let%lwt g = Os_db.User.user_of_userid key in
      Lwt.return (create_user_from_db0 g)
    with Os_db.No_such_resource -> Lwt.fail No_such_user
end)

(* Overwrite the function [user_of_userid] of [Os_db.User] and use
   the [get] function of the cache module. *)
let user_of_userid userid =
  let%lwt u, _ = MCache.get userid in
  Lwt.return u

let password_set userid =
  let%lwt _, s = MCache.get userid in
  Lwt.return s




(* -----------------------------------------------------------------

   All the followings functions are only helpers/wrappers around db
   functions ones. They generally use the type [t] of the module
   and get rid of the part of picking each field of the record [t].

*)

let empty = {
  userid = 0L;
  fn = "";
  ln = "";
  avatar = None;
}

(** Create new user. May raise [Already_exists] *)
let create ?password ?avatar ~firstname ~lastname email =
  try%lwt
    let%lwt userid = Os_db.User.userid_of_email email in
    Lwt.fail (Already_exists userid)
  with Os_db.No_such_resource ->
    let%lwt userid =
      Os_db.User.create ~firstname ~lastname ?password ?avatar email
    in
    user_of_userid userid

(* Overwrites the function [update] of [Os_db.User]
   to reset the cache *)
let update ?password ?avatar ~firstname ~lastname userid =
  let%lwt () = Os_db.User.update
             ?password ?avatar ~firstname ~lastname userid
  in
  MCache.reset userid;
  Lwt.return ()

let update' ?password t =
  update ?password ?avatar:t.avatar ~firstname:t.fn ~lastname:t.ln t.userid

let update_password password userid =
  let%lwt () = Os_db.User.update_password password userid in
  MCache.reset userid;
  Lwt.return ()

let update_avatar avatar userid =
  let%lwt () = Os_db.User.update_avatar avatar userid in
  MCache.reset userid;
  Lwt.return ()

let get_users ?pattern () =
  let%lwt users = Os_db.User.get_users ?pattern () in
  Lwt.return (List.map create_user_from_db users)

let set_pwd_crypt_fun a = Os_db.pwd_crypt_ref := a
