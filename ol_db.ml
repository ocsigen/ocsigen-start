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

let connect () = Lwt_PGOCaml.connect ~database:"ol" ()

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


(********* Tables *********)
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
       email text NOT NULL,
       creationdate timestamp NOT NULL DEFAULT(current_timestamp)
) >>

let contacts_table = <:table< contacts (
       userid bigint NOT NULL,
       contactid bigint NOT NULL
) >>

let preregister_table = <:table< preregister (
       email text NOT NULL
) >>

(********* Queries *********)
let new_preregister_email m =
  full_transaction_block
    (fun dbh ->
       Lwt_Query.query dbh
         <:insert<
            $preregister_table$ := { email = $string:m$; }
         >>)

let already_preregistered m =
  full_transaction_block
    (fun dbh ->
       try_lwt
         lwt e = Lwt_Query.view_one dbh
                   <:view< p | p in $preregister_table$;
                               p.email = $string:m$ >>
         in
          Lwt.return true
       with _ -> Lwt.return false)

let password_view =
  <:view< {email = e.email; pwd = u.pwd; userid=u.userid} |
      u in $users_table$;
      e in $emails_table$;
      u.userid = e.userid >>

let check_pwd login pwd =
  full_transaction_block
  (fun dbh ->
    lwt l = Lwt_Query.query dbh
    <:select< r | r in $password_view$;
                  r.email = $string:login$ >>
                  (* r.pwd = $string:pwd$ >> *)
    in
    (match l with
      | [] -> Lwt.fail Not_found
      | [r] -> (match Sql.getn r#pwd with
          | None -> Lwt.fail Not_found
          | Some h -> if Bcrypt.verify pwd (Bcrypt.hash_of_string h)
            then Lwt.return (r#!userid)
            else Lwt.fail Not_found)
      | r::_ -> Ocsigen_messages.warning "Db.check_pwd: should not occure. Check!";
        Lwt.return (r#!userid)
    ))


(** Returns the informations about one user from one uid.
    The results are cached in an Eliom reference with scope request. *)
let get_user, reset_user =
  let module M = Map.Make(struct type t = int64 let compare = compare end) in
  let cache = Eliom_reference.Volatile.eref
    ~scope:Eliom_common.request_scope M.empty
  in
  ((fun ?(default_avatar=Ol_common0.default_user_avatar) uid ->
    let table = Eliom_reference.Volatile.get cache in
    try Lwt.return (M.find uid table) with
      | Not_found ->
        full_transaction_block
          (fun dbh ->
            try_lwt
              lwt u =
                Lwt_Query.view_one dbh
                <:view< r | r in $users_table$;
                            r.userid = $int64:uid$ >>
              in
              let user =
                Ol_common0.create_user_from_db_info ~default_avatar u in
              let () = Eliom_reference.Volatile.set
                cache (M.add uid user table) in
              Lwt.return user
            with _ -> Lwt.fail Ol_common0.No_such_user)),
   (fun uid ->
     let table = Eliom_reference.Volatile.get cache in
     Eliom_reference.Volatile.set cache (M.remove uid table)))

(** Get the list of users corresponding to one name. *)
let get_users_from_name (fn, ln) =
  full_transaction_block
    (fun dbh ->
      Lwt_Query.view dbh
        <:view< r |
                r in $users_table$;
                r.firstname = $string:fn$;
                r.lastname = $string:ln$
        >>)



let existing_user0 dbh email =
  try_lwt
    lwt e = Lwt_Query.view_one dbh
      <:view< e | e in $emails_table$;
                  e.email = $string:email$ >>
    in
    Lwt.return (Some e#!userid)
  with _ -> Lwt.return None

let user_exists m =
  full_transaction_block
    (fun dbh ->
      match_lwt existing_user0 dbh m with
        | Some _ -> Lwt.return true
        | None -> Lwt.return false
    )


let add_activation_key0 dbh email key =
  Lwt_Query.query dbh
  <:insert< $activation_table$ :=
    {activationkey = $string:key$;
     email = $string:email$;
     creationdate = activation_table?creationdate } >>




let add_user0 dbh ?avatar email key =
  lwt () =
    match avatar with
      | Some avatar ->
        Lwt_Query.query dbh
        <:insert< $users_table$ := { userid = users_table?userid;
                                     firstname = $string:""$;
                                     lastname = $string:email$;
                                     pwd = $Sql.Op.null$;
                                     pic = $string:avatar$;
                                   } >>
      | None ->
        (* Do not put a default pic otherwise it will be cancelled
           when the user upload a new pic. *)
        Lwt_Query.query dbh
        <:insert< $users_table$ := { userid = users_table?userid;
                                     firstname = $string:""$;
                                     lastname = $string:email$;
                                     pwd = $Sql.Op.null$;
                                     pic = $Sql.Op.null$;
                                   } >>
  in
  (*VVV When user name is not set, I put the email in lastname
    with an empty firstname ...
    Then neither of them should be empty. *)
  lwt userid =
    Lwt_Query.view_one dbh <:view< {x = currval $users_table_id_seq$} >>
  in
  let userid = userid#!x in
  lwt () = Lwt_Query.query dbh
    <:insert< $emails_table$ := {
      email = $string:email$;
      userid = $int64:userid$ } >>
  in
  lwt () = add_activation_key0 dbh email key in
  Lwt.return userid


(** If the email does not exist, create it, add the activation id,
    and create the user.
    if it exists, set the new activation key. *)
let new_activation_key email key =
  full_transaction_block
    (fun dbh ->
      match_lwt existing_user0 dbh email with
        | Some _ -> add_activation_key0 dbh email key
        | None -> lwt _ = add_user0 dbh email key in Lwt.return ()
    )


let new_user_from_mail ?avatar email key =
  full_transaction_block
    (fun dbh ->
      match_lwt existing_user0 dbh email with
        | None -> add_user0 dbh ?avatar email key
        | Some userid -> Lwt.return userid
    )


(** Returns the userid corresponding to an activation key,
    and remove the activation key. Raise Not_found if the activation key
    does not exist. *)
let get_userid_from_activationkey key =
  full_transaction_block
    (fun dbh ->
      try_lwt
        lwt e = Lwt_Query.view_one dbh
          <:view< e |
                  e in $activation_table$;
                  e.activationkey = $string:key$ >>
        in
        lwt () = Lwt_Query.query dbh
          <:delete< r in $activation_table$ |
                    r.activationkey = $string:key$ >> in
        let email = e#!email in
        lwt e = Lwt_Query.view_one dbh
          <:view< e |
                  e in $emails_table$;
                  e.email = $string:email$ >>
        in
        Lwt.return (e#!userid)
      with Failure _ -> Lwt.fail Not_found
    )


(** sets the user info for existing user, and reset its value from the cache *)
let set_personal_data userid firstname lastname pwd =
  full_transaction_block (fun dbh ->
    lwt () = Lwt_Query.query dbh
      <:update< u in $users_table$ := { pwd = $string:pwd$;
                                        firstname = $string:firstname$;
                                        lastname = $string:lastname$;
                                      } |
                u.userid = $int64:userid$ >>
    in
    reset_user userid;
    Lwt.return ()
  )


let get_userslist () =
  full_transaction_block
    (fun dbh ->
      Lwt_Query.query dbh <:select< r | r in $users_table$ >>
    )

(* pics *)
let get_pic userid =
  lwt u = get_user userid in
  Lwt.return u.Ol_common0.useravatar

let set_pic userid pic =
  full_transaction_block (fun dbh ->
    lwt () = Lwt_Query.query dbh
      <:update< u in $users_table$ := { pic = $string:pic$;
                                      } |
                u.userid = $int64:userid$ >>
    in
    reset_user userid;
    Lwt.return ()
  )
