(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright (C) Université Paris Diderot, CNRS, INRIA, Be Sport.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

open Eliom_content.Html.F

[%%shared
  type id = Os_types.User.id [@@deriving json]

  type t = Os_types.User.t = {
      userid : id;
      fn : string;
      ln : string;
      avatar : string option;
    } [@@deriving json]
]

[%%server
  exception Already_exists of Os_types.User.id
  exception No_such_user
]

(** Create a user of type [t] using db informations. *)
let create_user_from_db0 (userid, fn, ln, avatar, pwdset) =
  Os_types.
  {
    userid = userid;
    fn = fn;
    ln = ln;
    avatar = avatar;
  },
  pwdset

let create_user_from_db d = fst (create_user_from_db0 d)

(** Getters functions. *)
let%shared userid_of_user (u : Os_types.User.t) = Os_types.(u.userid)
let%shared firstname_of_user u = Os_types.(u.fn)
let%shared lastname_of_user u = Os_types.(u.ln)
let%shared avatar_of_user u = Os_types.(u.avatar)

let%shared avatar_uri_of_avatar ?absolute_path avatar =
  Eliom_content.Html.F.make_uri ?absolute_path
    ~service:(Eliom_service.static_dir ()) ["avatars"; avatar]

let%shared avatar_uri_of_user ?absolute_path user =
  Eliom_lib.Option.map
    (avatar_uri_of_avatar ?absolute_path) (avatar_of_user user)

let%shared fullname_of_user user =
  String.concat " " [firstname_of_user user; lastname_of_user user]

let%shared is_complete user =
  not ((firstname_of_user user) = "" || (lastname_of_user user) = "")

let emails_of_user user =
  Os_db.User.emails_of_userid (userid_of_user user)

let email_of_user user =
  Os_db.User.email_of_userid (userid_of_user user)


include Os_db.User


(* Using cache tools to prevent multiple same database queries
   during the request. *)
module MCache = Os_request_cache.Make(
struct
  type key = Os_types.User.id
  type value = Os_types.User.t * bool

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

let update' ?password user =
  update
    ?password
    ?avatar:(avatar_of_user user)
    ~firstname:(firstname_of_user user)
    ~lastname:(lastname_of_user user)
    (userid_of_user user)

let update_password ~userid ~password =
  let%lwt () = Os_db.User.update_password userid password in
  MCache.reset userid;
  Lwt.return ()

let update_avatar ~userid ~avatar =
  let%lwt () = Os_db.User.update_avatar userid avatar in
  MCache.reset userid;
  Lwt.return ()

let get_users ?pattern () =
  let%lwt users = Os_db.User.get_users ?pattern () in
  Lwt.return (List.map create_user_from_db users)

let set_pwd_crypt_fun a = Os_db.pwd_crypt_ref := a

let is_email_validated ~userid ~email =
  Os_db.User.is_email_validated userid email

let is_main_email ~userid ~email =
  Os_db.User.is_main_email ~email ~userid
