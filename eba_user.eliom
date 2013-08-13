{shared{
  type shared_t = { uid: int64; firstname : string; lastname : string; avatar : string option; } deriving (Json)
}}

exception No_such_user

{shared{
  let firstname_of u = u.firstname
  let lastname_of u = u.lastname
  let avatar_of u = u.avatar
  let id_of u = u.uid
}}

module type T = sig
  type t = shared_t

  val user_of_uid : int64 -> t Lwt.t
  val explicit_reset_uid_from_cache : int64 -> unit

  val create : ?avatar:string -> act_key:string -> string -> int64 Lwt.t
  val set : int64
            -> ?act_key:string
            -> ?firstname:string
            -> ?lastname:string
            -> ?password:string
            -> ?avatar:string
            -> unit
            -> unit Lwt.t

  val uid_of_mail : string -> int64 option Lwt.t
  val uid_of_activationkey : string -> int64 option Lwt.t
end

module Make(M : sig
  module Database : Eba_db.T
end)
=
struct
  type t = shared_t

  let create_user_with (u : M.Database.U.t) =
    {
      uid = (Sql.get u#userid);
      firstname = (Sql.get u#firstname);
      lastname = (Sql.get u#lastname);
      avatar = (Sql.getn u#pic);
    }

  module MCache_in = struct
    type key_t = int64
    type value_t = t

    let compare = compare
    let get key =
      match_lwt M.Database.U.does_uid_exist key with
        | Some u -> Lwt.return (create_user_with u)
        | None -> Lwt.fail No_such_user
  end
  module MCache = Eba_cache.Make(MCache_in)

  let explicit_reset_uid_from_cache uid =
    MCache.reset (uid :> int64)

  let create ?avatar ~act_key mail =
    match_lwt M.Database.U.does_mail_exist mail with
     | Some uid -> Lwt.return uid
     | None ->
         lwt uid = M.Database.U.new_user ?avatar mail in
         lwt () = M.Database.U.set uid ~act_key () in
         Lwt.return uid

  (* FIXME: add_activation_key instead of set function to add one ? *)

  let set uid ?act_key ?firstname ?lastname ?password ?avatar () =
    match password with
      | None -> M.Database.U.set uid ?act_key ?firstname ?lastname ?avatar ()
      | Some p ->
          let p = Bcrypt.hash p in
          let password = Bcrypt.string_of_hash p in
          lwt () = M.Database.U.set uid ?act_key ?firstname ?lastname ~password ?avatar () in
          let () = explicit_reset_uid_from_cache uid in
          Lwt.return ()

  let verify_password mail passwd =
    M.Database.U.verify_password mail passwd

  let uid_of_mail mail =
    M.Database.U.does_mail_exist mail

  let uid_of_activationkey act_key =
    M.Database.U.does_activationkey_exist act_key

  let user_of_uid uid =
    ((MCache.get uid) :> t Lwt.t)

end

open Eliom_content.Html5
open Eliom_content.Html5.F

(* FIXME: the followings should be in another module I think, it concerns
 * only css/style, and should be maybe, into a "view" user module *)
{shared{
  let cls_avatar = "ol_avatar"
  let cls_mail = "ol_avatar"
  let cls_user = "ol_user"
  let cls_users = "ol_users"
  let cls_user_box = "ol_user_box"

  let default_user_avatar = "__ol_default_user_avatar"
  let mail_avatar = "__ol_default_mail_avatar"

  let name_of_user u = u.firstname

  let avatar_of_user u = match u.avatar with
    | None -> default_user_avatar
    | Some s -> s

  let id_of_user u = u.uid
}}

let make_pic_uri p =
  (make_uri (Eliom_service.static_dir ()) ["avatars" ; p])

let make_pic_string_uri ?absolute p =
  (make_string_uri
     ?absolute ~service:(Eliom_service.static_dir ()) ["avatars" ; p])

let print_user_name u =
  span ~a:[a_class ["ol_username"]] [pcdata (name_of_user u)]

let print_user_avatar ?(cls=cls_avatar) u =
  img
    ~a:[a_class [cls]]
    ~alt:(name_of_user u)
    ~src:(make_pic_uri (avatar_of_user u))
    ()

let print_user ?(cls=cls_user_box) u =
  span ~a:[a_class [cls]]
    [print_user_avatar u ; print_user_name u]

let print_users ?(cls=cls_users) l =
  D.span ~a:[a_class [cls]] (List.map print_user l)

