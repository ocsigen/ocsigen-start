exception No_such_resource

let dbh = PGOCaml.connect ~database:"%%%PROJECT_NAME%%%" ~port:3000 ()

let view_one rq =
  try List.nth rq 0
  with Failure _ -> raise No_such_resource

let view_one_lwt rq =
  try Lwt.return (view_one rq)
  with No_such_resource -> Lwt.fail No_such_resource

let view_one_opt rq =
  try Some (view_one rq)
  with No_such_resource -> None

module User = struct
  let create ?password ~firstname ~lastname email =
    PGSQL(dbh) "
    INSERT INTO users
    (firstname, lastname, password)
    VALUES ($firstname, $lastname, $?password)
    ";
    match view_one (PGSQL(dbh) "select currval('users_userid_seq')") with
    | None -> raise No_such_resource
    | Some uid ->
        PGSQL(dbh) "
        INSERT INTO emails
        (email, userid) VALUES ($email, $uid)
        ";
        Lwt.return uid

  let update ?password ~firstname ~lastname uid =
    (match password with
    | None ->
        PGSQL(dbh) "
        UPDATE users
        SET firstname = $firstname,
            lastname = $lastname
        WHERE userid = $uid
        "
    | Some password ->
        PGSQL(dbh) "
        UPDATE users
        SET firstname = $firstname,
            lastname = $lastname,
            password = $password
        WHERE userid = $uid
        ");
    print_endline "updated";
    Lwt.return ()

   let add_activationkey ~act_key uid =
    PGSQL(dbh) "
    INSERT INTO activation
    (userid, activationkey) VALUES ($uid, $act_key)
    ";
    Lwt.return ()

  let verify_password ~email ~password =
    (view_one_lwt (PGSQL(dbh) "
     SELECT t1.userid
     FROM users  as t1,
          emails as t2
     WHERE t1.userid = t2.userid
     AND t2.email = $email
     AND t1.password = $password
     "))

  let user_of_uid uid =
    ((view_one_lwt (PGSQL(dbh) "
     SELECT userid, firstname, lastname FROM users
     WHERE userid = $uid
     ")))

  let uid_of_activationkey act_key =
    let uid =
      (view_one_opt (PGSQL(dbh) "
       SELECT userid FROM activation
       WHERE activationkey = $act_key
       "))
    in
    (match uid with
     | None -> Lwt.fail No_such_resource
     | Some uid ->
         PGSQL(dbh) "
         DELETE FROM activation
         WHERE activationkey = $act_key
         ";
         Lwt.return uid)

  let uid_of_email email =
    (view_one_lwt (PGSQL(dbh) "
     SELECT t1.userid
     FROM users  as t1,
          emails as t2
     WHERE t1.userid = t2.userid
     AND t2.email = $email
     "))

  let email_of_uid uid =
    (view_one_lwt (PGSQL(dbh) "
     SELECT t2.email
     FROM users  as t1,
          emails as t2
     WHERE t1.userid = t2.userid
     AND t1.userid = $uid
     "))

end

module Groups = struct
  let create ?description name =
    PGSQL(dbh) "
    INSERT INTO groups
    (description, name) VALUES ($?description, $name)
    ";
    Lwt.return ()

  let group_of_name name =
    let group =
      view_one_opt (PGSQL(dbh) "
      SELECT groupid, name, description FROM groups
      WHERE name = $name
      ")
    in
    Lwt.return
      (match group with
        | None -> raise No_such_resource
        | Some group -> group)

  let add_user_in_group ~groupid ~userid =
    PGSQL(dbh) "
    INSERT INTO user_groups
    (userid, groupid) VALUES ($userid, $groupid)
    ";
    Lwt.return ()

  let remove_user_in_group ~groupid ~userid =
    PGSQL(dbh) "
    DELETE FROM user_groups
    WHERE groupid = $groupid
    AND userid = $userid
    ";
    Lwt.return ()

  let in_group ~groupid ~userid =
    try_lwt
      lwt _ =
        (view_one_lwt (PGSQL(dbh) "
         SELECT * FROM user_groups
         WHERE groupid = $groupid
         AND userid = $userid
         "))
      in Lwt.return true
    with No_such_resource -> Lwt.return false

  let all () =
    Lwt.return
      (PGSQL(dbh) "
       SELECT groupid, name, description FROM groups
       ")
end
