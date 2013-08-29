(* CHARLY: This module is used by the widget completion. We have to provide a
 * lots of helper to fit the functor condition of the widget. It's really
 * boring to define all these accessors.. Maybe it could be better to turn it
 * into an object ? And juste provide a function which transform a user type
 * into an user completion type ? *)
{shared{
  include Eba_common0
  type member = user deriving (Json)
}}
  (*

{server{
  type t = string deriving (Json)

  let get_users_from_server pattern =
    lwt ul = Eba_db.get_userslist () in
    let ul = List.map (Eba_common0.create_user_from_db_info) ul in
    Lwt.return ul

  let get_memberlist =
    let query p =
      lwt userlist = Eba_db.get_userslist () in
      let userlist = List.map Eba_common0.create_user_from_db_info userlist in
      let f u =
        let s =  Ew_accents.without (Eba_common0.name_of_user u) in
          Ew_completion.is_completed_by (Ew_accents.without p) s
      in
      Lwt.return (List.filter f userlist)
    in
    Eliom_pervasives.server_function Json.t<string> query
}}

{client{

  let alert_member u =
    Eliom_lib.alert "%s" u.username

  let get_memberlist : (string, member list) Eliom_pervasives.server_function
    = %get_memberlist

  let newmember_from_mail m =
    Lwt.return {
      userid = (Int64.of_int 0);
      username = m;
      useravatar = None;
      new_user = true;
    }

  let mem_member u1 u2 =
    (u1.userid = u2.userid)

  let id_of_member u =
    u.userid

  let name_of_member u =
    u.username

  let avatar_of_member u =
    match u.useravatar with
      | None -> default_user_avatar
      | Some a -> (make_pic_string_uri a)

  let class_of_memberbox _ =
    "eba_memberbox"

  let class_of_member _ =
    "eba_member"

  let cls_member_selector =
    "eba_member_selector"

  let cls_member_input =
    "eba_member_input"

  let cls_members =
    "eba_members"

  let cls_mailbox =
    "eba_mailbox"

}}
   *)
