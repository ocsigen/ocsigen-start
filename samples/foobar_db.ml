(* Copyright Vincent Balat *)

let (>>=) = Lwt.bind

(********* Macaque initialisation *********)
module Lwt_thread = struct
  include Lwt
  include Lwt_chan
end
module Lwt_PGOCaml = PGOCaml_generic.Make(Lwt_thread)
module Lwt_Query = Query.Make_with_Db(Lwt_thread)(Lwt_PGOCaml)
module PGOCaml = Lwt_PGOCaml

let name = "eba"
let port = 5432
let workers = 16

let hash s =
  Bcrypt.string_of_hash (Bcrypt.hash s)

let verify s1 s2 =
  Bcrypt.verify s1 (Bcrypt.hash_of_string s2)

let connect () =
  Lwt_PGOCaml.connect
    ~port
    ~database:name
    ()

let validate db =
  try_lwt
    lwt () = Lwt_PGOCaml.ping db in
    Lwt.return true
  with _ ->
    Lwt.return false

let pool : (string, bool) Hashtbl.t Lwt_PGOCaml.t Lwt_pool.t =
  Lwt_pool.create 16 ~validate connect

let transaction_block db f =
  Lwt_PGOCaml.begin_work db >>= fun _ ->
  try_lwt
     lwt r = f () in
     lwt () = Lwt_PGOCaml.commit db in
     Lwt.return r
  with e ->
     lwt () = Lwt_PGOCaml.rollback db in
     Lwt.fail e

let full_transaction_block f =
  Lwt_pool.use pool (fun db -> transaction_block db (fun () -> f db))

let users_table_id_seq = <:sequence< bigserial "users_userid_seq" >>

let users_table = <:table< users (
       userid bigint NOT NULL DEFAULT(nextval $users_table_id_seq$),
       pwd text,
       firstname text NOT NULL,
       lastname text NOT NULL,
       pic text
) >>

let emails_table = <:table< emails (
       email text NOT NULL,
       userid bigint NOT NULL
) >>

let activation_table = <:table< activation (
       activationkey text NOT NULL,
       userid bigint NOT NULL,
       creationdate timestamp NOT NULL DEFAULT(current_timestamp)
) >>

let groups_table_id_seq = <:sequence< bigserial "groups_groupid_seq" >>

let groups_table = <:table< groups (
       groupid bigint NOT NULL DEFAULT(nextval $groups_table_id_seq$),
       name text NOT NULL,
       description text
) >>

let user_groups_table = <:table< user_groups (
       userid bigint NOT NULL,
       groupid bigint NOT NULL
) >>


module User = struct

  type t = {
    uid : int64;
    fn : string;
    ln : string;
  }

  let create_user_with u =
    {
      uid = Sql.get u#userid;
      fn = Sql.get u#firstname;
      ln = Sql.get u#lastname;
    }

  let new_user ?password ~email ext =
    full_transaction_block
      (fun dbh ->
         lwt () =
           match password with
             | None ->
                 Lwt_Query.query dbh
                   <:insert< $users_table$ := { userid = users_table?userid;
                                                firstname = $string:""$;
                                                lastname = $string:email$;
                                                pwd = $Sql.Op.null$;
                                                pic = $Sql.Op.null$;
                                              } >>
             | Some p ->
                 Lwt_Query.query dbh
                   <:insert< $users_table$ := { userid = users_table?userid;
                                                firstname = $string:""$;
                                                lastname = $string:email$;
                                                pwd = $string:p$;
                                                pic = $Sql.Op.null$;
                                              } >>
         in
         lwt userid =
           Lwt_Query.view_one dbh
             <:view< { x = currval $users_table_id_seq$ } >>
         in
         let userid = userid#!x in
         lwt () =
           Lwt_Query.query dbh
             <:insert< $emails_table$ := { email = $string:email$;
                                           userid = $int64:userid$
                                         } >>
         in
         Lwt.return userid)

  let attach_activationkey ~act_key uid =
    full_transaction_block
      (fun dbh ->
         Lwt_Query.query dbh
           <:insert<
           $activation_table$ := { activationkey = $string:act_key$;
                                   userid = $int64:uid$;
                                   creationdate = activation_table?creationdate
                                 } >>)

  let update ?password u =
    full_transaction_block
      (fun dbh ->
        let uid = Eba_shared.User.uid_of_user u in
        let ext = Eba_shared.User.ext_of_user u in
        let fn = ext.fn in
        let ln = ext.ln in
        match password with
        | None ->
           (Lwt_Query.query dbh
              <:update< u in $users_table$ := { firstname = $string:fn$;
                                                lastname = $string:ln$;
                                              } | u.userid = $int64:uid$ >>)
        | Some p ->
           (Lwt_Query.query dbh
              <:update< u in $users_table$ := { firstname = $string:fn$;
                                                lastname = $string:ln$;
                                                pwd = $string:p$;
                                              } | u.userid = $int64:uid$ >>))

  let user_of_uid uid =
    let email_view =
      <:view< { email = e.email;
                userid = u.userid;
                firstname = u.firstname;
                lastname = u.lastname;
              } | u in $users_table$;
                  e in $emails_table$;
                  u.userid = e.userid >>
    in
    full_transaction_block
      (fun dbh ->
         try_lwt
           lwt u =
             Lwt_Query.view_one dbh
               <:view< u | u in $email_view$;
                           u.userid = $int64:uid$ >>
           in
           Lwt.return (Some (create_user_with u))
         with
           | _ -> Lwt.return None)

  let verify_password login pwd =
    let password_view =
      <:view< { email = e.email; pwd = u.pwd; userid = u.userid }
                | u in $users_table$;
                  e in $emails_table$;
                  u.userid = e.userid >>
    in
    full_transaction_block
      (fun dbh ->
        lwt l =
          Lwt_Query.query dbh
            <:select< r | r in $password_view$;
                          r.email = $string:login$ >>
                       (* r.pwd = $string:pwd$ >> *)
        in
        match l with
          | [] -> Lwt.return None
          | [r] ->
              (match Sql.getn r#pwd with
                 | None -> Lwt.return None
                 | Some h ->
                     if verify pwd h
                     then Lwt.return (Some (r#!userid))
                     else Lwt.return None)
          | r::_ ->
              Ocsigen_messages.warning "Db.check_pwd: should not occure. Check!";
              Lwt.return (Some (r#!userid)))

  let uid_of_email email =
    full_transaction_block
      (fun dbh ->
        try_lwt
          lwt e =
            Lwt_Query.view_one dbh
              <:view< e | e in $emails_table$;
                          e.email = $string:email$ >>
          in
          Lwt.return (Some e#!userid)
        with _ -> Lwt.return None)

  let uid_of_activationkey act_key =
    full_transaction_block
      (fun dbh ->
         try_lwt
           lwt e =
             Lwt_Query.view_one dbh
               <:view< e | e in $activation_table$;
                       e.activationkey = $string:act_key$ >>
           in
           lwt () =
             Lwt_Query.query dbh
               <:delete< r in $activation_table$ |
                         r.activationkey = $string:act_key$ >>
           in
           Lwt.return (Some (e#!userid))
         with Failure _ -> Lwt.return None)
end

module Groups = struct

  open Eba_shared.Groups

  let create_group_with g =
    let open Eba_types.Groups in
    {
      id   = Sql.get g#groupid;
      name = Sql.get g#name;
      desc = Sql.getn g#description;
    }

  module Q = struct
    let is_user_in_group dbh ~userid ~groupid =
      try_lwt
        lwt _ = Lwt_Query.view_one dbh
          <:view< ug | ug in $user_groups_table$;
                       ug.userid = $int64:userid$;
                       ug.groupid = $int64:groupid$;
          >>
        in Lwt.return true
      with _ -> Lwt.return false
  end

  let get_group name =
    full_transaction_block
      (fun dbh ->
         try_lwt
           lwt g = Lwt_Query.view_one dbh
             <:view< g | g in $groups_table$;
                         g.name = $string:name$ >>;
           in
           Lwt.return (Some (create_group_with g))
         with _ -> Lwt.return None)

  let new_group ?description name =
    full_transaction_block
      (fun dbh ->
         try_lwt
           match description with
             | None ->
                 Lwt_Query.query dbh
                   <:insert< $groups_table$ := { groupid = groups_table?groupid;
                                                 name = $string:name$;
                                                 description = $Sql.Op.null$
                                               } >>
             | Some d ->
                 Lwt_Query.query dbh
                   <:insert< $groups_table$ := { groupid = groups_table?groupid;
                                                 name = $string:name$;
                                                 description = $string:d$
                                               } >>
         with _ -> Lwt.return ())

  let in_group ~group ~userid =
    full_transaction_block
      (fun dbh ->
         let groupid = id_of_group group in
         Q.is_user_in_group dbh ~userid ~groupid)

  let add_user_in_group ~group ~userid =
    full_transaction_block
      (fun dbh ->
         let groupid = id_of_group group in
         lwt b = Q.is_user_in_group dbh ~userid ~groupid in
         if b
         then Lwt.return ()
         else
           Lwt_Query.query dbh
             <:insert< $user_groups_table$ := { userid = $int64:userid$;
                                                groupid = $int64:groupid$
                                              } >>)

  let remove_user_in_group ~group ~userid =
    full_transaction_block
      (fun dbh ->
         let groupid = id_of_group group in
         Lwt_Query.query dbh
           <:delete< ug in $user_groups_table$
                     | ug.userid = $int64:userid$;
                       ug.groupid = $int64:groupid$ >>)

  let all () =
    full_transaction_block
      (fun dbh ->
         lwt l =
           Lwt_Query.query dbh
             <:select< g | g in $groups_table$ >>
         in
         Lwt.return (List.map create_group_with l))

end
