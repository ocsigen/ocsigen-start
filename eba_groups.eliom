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

exception No_such_group

module MCache_in = struct
  type key_t = string
  type value_t = t

  let compare = compare
  let get key =
    print_endline ("get with key="^key);
    match_lwt Eba_db.group_exists key with
      | Some g -> Lwt.return (create_group_with g)
      | None -> Lwt.fail No_such_group
end
module MCache = Eba_cache.Make(MCache_in)

(** creates the group in the database if it does
  * not exist, or returns its id as an abstract value *)
let create ?description name =
  print_endline "eba_group.create";
   match_lwt Eba_db.group_exists name with
    | Some g -> Lwt.return (create_group_with g)
    | None ->
        (* we can't use the cache here, because we can use create at top-level
         * and we don't have access to request scope at top-level *)
        lwt () = Eba_db.new_group ?description name in
        lwt g = Eba_db.get_group name in
        Lwt.return (create_group_with g)

let get name =
  print_endline "eba_group.get";
  try_lwt
    lwt g = MCache.get name in
    Lwt.return (Some g)
  with
    | No_such_group -> Lwt.return None

let add_user ~userid ~group =
  Eba_db.add_user_in_group
    ~userid
    ~groupid:group.id

let remove_user ~userid ~group =
  Eba_db.remove_user_in_group
    ~userid
    ~groupid:group.id

let in_group ~userid ~group =
  Eba_db.is_user_in_group
    ~userid
    ~groupid:group.id

let all () =
  lwt l = Eba_db.get_groups () in
  let put_in_cache g =
    let g = create_group_with g in
    let () = MCache.set g.name g in
    g
  in
  Lwt.return
    (List.map
       (put_in_cache)
       (l))

{shared{
  let name_of group = group.name
  let desc_of group = group.desc
}}

let admin = create "admin"
