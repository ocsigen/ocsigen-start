exception No_such_resource

let (>>=) = Lwt.bind

module Lwt_thread = struct
  include Lwt
  include Lwt_chan
end
module Lwt_PGOCaml = PGOCaml_generic.Make(Lwt_thread)
module Lwt_Query = Query.Make_with_Db(Lwt_thread)(Lwt_PGOCaml)
module PGOCaml = Lwt_PGOCaml

let connect () =
  Lwt_PGOCaml.connect ~port:3000 ~database:"foobar" ()

let validate db =
  try_lwt
    lwt () = Lwt_PGOCaml.ping db in
    Lwt.return true
  with _ ->
    Lwt.return false

let transaction_block db f =
  Lwt_PGOCaml.begin_work db >>= fun _ ->
  try_lwt
    lwt r = f () in
    lwt () = Lwt_PGOCaml.commit db in
    Lwt.return r
  with e ->
    lwt () = Lwt_PGOCaml.rollback db in
    Lwt.fail e

let pool : (string, bool) Hashtbl.t Lwt_PGOCaml.t Lwt_pool.t =
  Lwt_pool.create 16 ~validate connect

let full_transaction_block f =
  Lwt_pool.use pool (fun db -> transaction_block db (fun () -> f db))

let view_one rq =
  try List.hd rq
  with Failure _ -> raise No_such_resource

let view_one_lwt rq =
  try_lwt
    lwt rq = rq in
    Lwt.return (view_one rq)
  with No_such_resource -> Lwt.fail No_such_resource

let view_one_opt rq =
  try_lwt
    lwt rq = rq in
    Lwt.return (Some (view_one rq))
  with No_such_resource -> Lwt.return None

module User = struct

  let select_user_from_email_q dbh email =
      (view_one_lwt (PGSQL(dbh) "
         SELECT t1.userid
         FROM users  as t1,
              emails as t2
         WHERE t1.userid = t2.userid
         AND t2.email = $email
         "))

  let is_registered email =
    full_transaction_block (fun dbh ->
      try_lwt
        lwt _ = select_user_from_email_q dbh email in
        Lwt.return true
      with No_such_resource -> Lwt.return false)

  let add_preregister email =
    full_transaction_block (fun dbh ->
      (PGSQL(dbh) "
         INSERT INTO preregister
         (email) VALUES ($email)
         "))

  let remove_preregister email =
    full_transaction_block (fun dbh ->
      (PGSQL(dbh) "
        DELETE FROM preregister
        WHERE email = $email
        "))

  let is_preregistered email =
    full_transaction_block (fun dbh ->
      try_lwt
        lwt _ =
          view_one_lwt (PGSQL(dbh) "
          SELECT email FROM preregister
          WHERE email = $email
          ")
        in Lwt.return true
      with No_such_resource -> Lwt.return false)

  let all ?(limit = 10L) () =
    full_transaction_block (fun dbh ->
      (PGSQL(dbh) "
        SELECT email FROM preregister
        LIMIT $limit
        "))
  let create ?password ~firstname ~lastname email =
    full_transaction_block (fun dbh ->
      lwt () = PGSQL(dbh) "
        INSERT INTO users
        (firstname, lastname, password)
        VALUES ($firstname, $lastname, $?password)
       "
      in
      match_lwt PGSQL(dbh) "select currval('users_userid_seq')" with
      | Some uid::_ ->
        lwt () = PGSQL(dbh) "
          INSERT INTO emails
          (email, userid) VALUES ($email, $uid)
          "
        in
        lwt () = remove_preregister email in
        Lwt.return uid
      | _ -> Lwt.fail No_such_resource
    )

  let update ?password ~firstname ~lastname uid =
    full_transaction_block (fun dbh ->
      (match password with
        | None ->
          PGSQL(dbh) "
        UPDATE users
        SET firstname = $firstname,
            lastname = $lastname
        WHERE userid = $uid
        "
        | Some password ->
          let password = Bcrypt.string_of_hash (Bcrypt.hash password) in
          PGSQL(dbh) "
        UPDATE users
        SET firstname = $firstname,
            lastname = $lastname,
            password = $password
        WHERE userid = $uid
        "))

   let add_activationkey ~act_key uid =
    full_transaction_block (fun dbh ->
      PGSQL(dbh) "
        INSERT INTO activation
        (userid, activationkey) VALUES ($uid, $act_key)
        ")

  let verify_password ~email ~password =
    full_transaction_block (fun dbh ->
      lwt (uid,password') =
        (view_one_lwt (PGSQL(dbh) "
         SELECT t1.userid, t1.password
         FROM users  as t1,
              emails as t2
         WHERE t1.userid = t2.userid
         AND t2.email = $email
         "))
      in
      match password' with
      | None -> Lwt.fail No_such_resource
      | Some password' ->
          if Bcrypt.verify password (Bcrypt.hash_of_string password')
          then Lwt.return uid
          else Lwt.fail No_such_resource)

  let user_of_uid uid =
    full_transaction_block (fun dbh ->
      (view_one_lwt (PGSQL(dbh) "
         SELECT userid, firstname, lastname FROM users
         WHERE userid = $uid
         ")))

  let uid_of_activationkey act_key =
    full_transaction_block (fun dbh ->
      lwt uid =
        (view_one_opt (PGSQL(dbh) "
           SELECT userid FROM activation
           WHERE activationkey = $act_key
           "))
      in
      (match uid with
        | None -> Lwt.fail No_such_resource
        | Some uid ->
          lwt () = PGSQL(dbh) "
            DELETE FROM activation
            WHERE activationkey = $act_key
            "
          in
          Lwt.return uid))

  let email_of_uid uid =
    full_transaction_block (fun dbh ->
      (view_one_lwt (PGSQL(dbh) "
         SELECT t2.email
         FROM users  as t1,
              emails as t2
         WHERE t1.userid = t2.userid
         AND t1.userid = $uid
         ")))

  let uid_of_email email =
    full_transaction_block (fun dbh ->
         select_user_from_email_q dbh email)

end

module Groups = struct
  let create ?description name =
    full_transaction_block (fun dbh ->
      PGSQL(dbh) "
        INSERT INTO groups
        (description, name) VALUES ($?description, $name)
        ")

  let group_of_name name =
    full_transaction_block (fun dbh ->
      lwt group =
        view_one_opt (PGSQL(dbh) "
          SELECT groupid, name, description FROM groups
          WHERE name = $name
          ")
      in
      match group with
        | None -> Lwt.fail No_such_resource
        | Some group -> Lwt.return group)

  let add_user_in_group ~groupid ~userid =
    full_transaction_block (fun dbh ->
      PGSQL(dbh) "
        INSERT INTO user_groups
        (userid, groupid) VALUES ($userid, $groupid)
        ")

  let remove_user_in_group ~groupid ~userid =
    full_transaction_block (fun dbh ->
      PGSQL(dbh) "
        DELETE FROM user_groups
        WHERE groupid = $groupid
        AND userid = $userid
        ")

  let in_group ~groupid ~userid =
    full_transaction_block (fun dbh ->
      try_lwt
        lwt _ =
          view_one_lwt (PGSQL(dbh) "
            SELECT * FROM user_groups
            WHERE groupid = $groupid
            AND userid = $userid
            ")
        in Lwt.return true
      with No_such_resource -> Lwt.return false)

  let all () =
    full_transaction_block (fun dbh ->
      PGSQL(dbh) "
        SELECT groupid, name, description FROM groups
        ")
end
