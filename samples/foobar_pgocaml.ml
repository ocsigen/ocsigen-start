exception No_such_resource

let dbh = PGOCaml.connect ~database:"foobar" ~port:3000 ()

let view_one rq =
  List.nth rq 0

let view_one_opt rq =
  try Some (view_one rq)
  with Failure _ -> None

module User = struct
  open Eba_types.User
  open Foobar_types.User

  type ext_t = Foobar_types.User.ext_t

  let new_user ?password ~email ext =
    let firstname = ext.fn in
    let lastname = ext.ln in
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

  let update ?password user =
    let uid = user.uid in
    let firstname = user.ext.fn in
    let lastname = user.ext.ln in
    PGSQL(dbh) "
    UPDATE users
    SET firstname = $firstname,
        lastname = $lastname,
        password = $?password
    WHERE userid = $uid
    ";
    Lwt.return ()

   let attach_activationkey ~act_key uid =
    PGSQL(dbh) "
    INSERT INTO activation
    (userid, activationkey) VALUES ($uid, $act_key)
    ";
    Lwt.return ()

  let verify_password email password =
    Lwt.return
      (view_one_opt (PGSQL(dbh) "
       SELECT t1.userid
       FROM users  as t1,
            emails as t2
       WHERE t1.userid = t2.userid
       AND t2.email = $email
       AND t1.password = $password
       "))

  let user_of_uid uid =
    let (uid, fn, ln) =
      view_one (PGSQL(dbh) "
      SELECT userid, firstname, lastname FROM users
      WHERE userid = $uid
      ")
    in
    Lwt.return (Some {
      uid = uid;
      ext = {
        fn = fn;
        ln = ln;
      }
    })

  let uid_of_activationkey act_key =
    let uid =
      (view_one_opt (PGSQL(dbh) "
       SELECT userid FROM activation
       WHERE activationkey = $act_key
       "))
    in
    Lwt.return
      (match uid with
       | None -> None
       | Some uid ->
           PGSQL(dbh) "
           DELETE FROM activation
           WHERE activationkey = $act_key
           ";
           Some uid)

  let uid_of_email email =
    Lwt.return
      (view_one_opt (PGSQL(dbh) "
       SELECT t1.userid
       FROM users  as t1,
            emails as t2
       WHERE t1.userid = t2.userid
       AND t2.email = $email
       "))

end

module Groups = struct
  open Eba_types.Groups

  let record_group (groupid, name, description) =
    {
      id = groupid;
      name = name;
      desc = description;
    }

  let new_group ?description name =
    PGSQL(dbh) "
    INSERT INTO groups
    (description, name) VALUES ($?description, $name)
    ";
    Lwt.return ()

  let get_group name =
    let group =
      view_one_opt (PGSQL(dbh) "
      SELECT groupid, name, description FROM groups
      WHERE name = $name
      ")
    in
    Lwt.return
      (match group with
        | None -> None
        | Some group -> Some (record_group group))

  let add_user_in_group ~group ~userid =
    let groupid = group.id in
    PGSQL(dbh) "
    INSERT INTO user_groups
    (userid, groupid) VALUES ($userid, $groupid)
    ";
    Lwt.return ()

  let remove_user_in_group ~group ~userid =
    let groupid = group.id in
    PGSQL(dbh) "
    DELETE FROM user_groups
    WHERE groupid = $groupid
    AND userid = $userid
    ";
    Lwt.return ()

  let in_group ~group ~userid =
    let groupid = group.id in
    try
      ignore (view_one (PGSQL(dbh) "
        SELECT * FROM user_groups
        WHERE groupid = $groupid
        AND userid = $userid
        "));
      Lwt.return true
    with No_such_resource -> Lwt.return false

  let all () =
    Lwt.return
      (List.map
        (record_group)
        (PGSQL(dbh) "
        SELECT groupid, name, description FROM groups
        "))

end
