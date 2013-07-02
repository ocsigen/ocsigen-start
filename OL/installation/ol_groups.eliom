(** abstract type which correspond to a group.
  * a user belongs to one or more groups, each
  * group grants him some special rights (e.g:
  * beta-user, admin or whatever. *)
{shared{
  type t = { id : int64; name : string; desc : string option } deriving (Json)
}}

let create_group_with g =
  {
    id   = (Sql.get g#groupid);
    name = (Sql.get g#name);
    desc = (Sql.getn g#description);
  }

(** creates the group in the database if it does
  * not exist, or returns its id as an abstract value *)
let create name ?description () =
  match_lwt Ol_db.group_exists name with
    | Some g -> Lwt.return (create_group_with g)
    | None ->
        lwt () = Ol_db.new_group name ?description in
  lwt g = Ol_db.get_group name in
  Lwt.return (create_group_with g)

let get name =
  match_lwt Ol_db.group_exists name with
    | Some g -> Lwt.return (Some (create_group_with g))
    | None -> Lwt.return None

let add_user ~userid ~group =
  Ol_db.add_user_in_group
    ~userid
    ~groupid:group.id

let remove_user ~userid ~group =
  Ol_db.remove_user_in_group
    ~userid
    ~groupid:group.id

let in_group ~userid ~group =
  Ol_db.is_user_in_group
    ~userid
    ~groupid:group.id

let all () =
  lwt l = Ol_db.get_groups () in
  Lwt.return (List.map (create_group_with) l)

{shared{
  let name_of group = group.name
  let desc_of group = group.desc
}}

let admin = create "admin" ()
