{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

exception No_such_user

module type T = sig
  type t = Eba_types.User.t

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

  val is_new : t -> bool

  val users_of_pattern : string -> t list Lwt.t

  val user_of_uid : int64 -> t Lwt.t
  val uid_of_mail : string -> int64 option Lwt.t
  val uid_of_activationkey : string -> int64 option Lwt.t

  val default_avatar : string
  val make_avatar_uri : string -> Eliom_content.Html5.uri
  val make_avatar_string_uri : ?absolute:bool -> string -> string

  val firstname_of_user : t -> string
  val lastname_of_user : t -> string
  val fullname_of_user : t -> string
  val avatar_of_user : t -> string
  val uid_of_user : t -> int64
end

module Make(M : sig
  module Database : Eba_db.T
end)
=
struct
  include Eba_shared.User

  let create_user_with (u : M.Database.U.t) =
    let open Eba_types.User in
    {
      uid = (Sql.get u#userid);
      firstname = (Sql.get u#firstname);
      lastname = (Sql.get u#lastname);
      avatar = (Sql.getn u#pic);
    }

  module MCache = Eba_tools.Cache_f.Make(
  struct
    type key_t = int64
    type value_t = t

    let compare = compare
    let get key =
      match_lwt M.Database.U.does_uid_exist key with
        | Some u -> Lwt.return (create_user_with u)
        | None -> Lwt.fail No_such_user
  end)

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
    lwt () = M.Database.U.set uid ?act_key ?firstname ?password ?lastname ?avatar () in
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

  let users_of_pattern pattern =
    lwt usersl = M.Database.U.get_userslist () in
    let usersl = List.map (create_user_with) (usersl) in
    let f u =
      let fulln = Ew_accents.without (fullname_of_user u) in
      Ew_completion.is_completed_by (Ew_accents.without pattern) fulln
    in
    Lwt.return (List.filter f usersl)

end

open Eliom_content.Html5
open Eliom_content.Html5.F

(* FIXME: the followings should be in another module I think, it concerns
 * only css/style, and should be maybe, into a "view" user module *)
{shared{
  let cls_avatar = "eba_avatar"
  let cls_mail = "eba_avatar"
  let cls_user = "eba_user"
  let cls_users = "eba_users"
  let cls_user_box = "eba_user_box"
}}
