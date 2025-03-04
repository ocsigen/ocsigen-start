(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright (C) Université Paris Diderot, CNRS, INRIA, Be Sport.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

include Os_core_db

exception No_such_resource
exception Wrong_password
exception Password_not_set
exception No_such_user
exception Empty_password
exception Main_email_removal_attempt
exception Account_not_activated

let ( >>= ) = Lwt.bind

(*****************************************************************************)

let one f ~success ~fail q = f q >>= function r :: _ -> success r | _ -> fail

let pwd_crypt_ref =
  ref
    ( (fun password -> Bcrypt.string_of_hash (Bcrypt.hash password))
    , fun _ password1 password2 ->
        Bcrypt.verify password1 (Bcrypt.hash_of_string password2) )

module Email = struct
  let available email =
    one without_transaction
      ~success:(fun _ -> Lwt.return_false)
      ~fail:Lwt.return_true
      (fun dbh ->
        [%pgsql
          dbh
            "SELECT 1
             FROM ocsigen_start.emails
             JOIN ocsigen_start.users USING (userid)
             WHERE email = $email"])
end

module User = struct
  exception Invalid_action_link_key of Os_types.User.id

  let userid_of_email email =
    one without_transaction
      ~success:(fun userid -> Lwt.return userid)
      ~fail:(Lwt.fail No_such_resource)
      (fun dbh ->
        [%pgsql
          dbh
            "SELECT userid
           FROM ocsigen_start.users JOIN ocsigen_start.emails USING (userid)
           WHERE email = $email"])

  let is_registered email =
    try%lwt
      let%lwt _ = userid_of_email email in
      Lwt.return_true
    with No_such_resource -> Lwt.return_false

  let is_email_validated userid email =
    one without_transaction
      ~success:(fun _ -> Lwt.return_true)
      ~fail:Lwt.return_false
      (fun dbh ->
        [%pgsql
          dbh
            "SELECT 1 FROM ocsigen_start.emails
           WHERE userid = $userid AND email = $email AND validated"])

  let set_email_validated userid email =
    without_transaction @@ fun dbh ->
    [%pgsql
      dbh
        "UPDATE ocsigen_start.emails SET validated = true
         WHERE userid = $userid AND email = $email"]

  let add_actionlinkkey ?(autoconnect = false) ?(action = `AccountActivation)
      ?(data = "") ?(validity = 1L) ?expiry ~act_key ~userid ~email ()
    =
    let action =
      match action with
      | `AccountActivation -> "activation"
      | `PasswordReset -> "passwordreset"
      | `Custom s -> s
    in
    without_transaction @@ fun dbh ->
    [%pgsql
      dbh
        "INSERT INTO ocsigen_start.activation
           (userid, email, action, autoconnect, data,
            validity, activationkey, expiry)
         VALUES ($userid, $email, $action, $autoconnect, $data,
                 $validity, $act_key, $?expiry)"]

  let add_preregister email =
    without_transaction @@ fun dbh ->
    [%pgsql dbh "INSERT INTO ocsigen_start.preregister (email) VALUES ($email)"]

  let remove_preregister0 dbh email =
    [%pgsql dbh "DELETE FROM ocsigen_start.preregister WHERE email = $email"]

  let remove_preregister email =
    without_transaction @@ fun dbh -> remove_preregister0 dbh email

  let is_preregistered email =
    one without_transaction
      ~success:(fun _ -> Lwt.return_true)
      ~fail:Lwt.return_false
      (fun dbh ->
        [%pgsql
          dbh "SELECT 1 FROM ocsigen_start.preregister WHERE email = $email"])

  let all ?(limit = 10L) () =
    without_transaction @@ fun dbh ->
    [%pgsql dbh "SELECT email FROM ocsigen_start.preregister LIMIT $limit"]

  let create ?password ?avatar ?language ?email ~firstname ~lastname () =
    if password = Some ""
    then Lwt.fail_with "empty password"
    else
      full_transaction_block (fun dbh ->
          let password_o =
            Eliom_lib.Option.map (fun p -> fst !pwd_crypt_ref p) password
          in
          let%lwt userid =
            match%lwt
              [%pgsql
                dbh
                  "INSERT INTO ocsigen_start.users
                   (firstname, lastname, main_email, password, avatar, language)
                 VALUES ($firstname, $lastname, $?email,
                         $?password_o, $?avatar,  $?language)
                 RETURNING userid"]
            with
            | [userid] -> Lwt.return userid
            | _ -> assert false
          in
          let%lwt () =
            match email with
            | Some email ->
                let%lwt () =
                  [%pgsql
                    dbh
                      "INSERT INTO ocsigen_start.emails (email, userid)
                   VALUES ($email, $userid)"]
                in
                remove_preregister0 dbh email
            | None -> Lwt.return_unit
          in
          Lwt.return userid)

  let update ?password ?avatar ?language ~firstname ~lastname userid =
    if password = Some ""
    then Lwt.fail_with "empty password"
    else
      let password =
        match password with
        | Some password -> Some (fst !pwd_crypt_ref password)
        | None -> None
      in
      without_transaction @@ fun dbh ->
      [%pgsql
        dbh
          "UPDATE ocsigen_start.users
           SET firstname = $firstname,
               lastname = $lastname,
               password = COALESCE($?password, password),
               avatar = COALESCE($?avatar, avatar),
               language = COALESCE($?language, language)
           WHERE userid = $userid"]

  let update_password ~userid ~password =
    if password = ""
    then Lwt.fail_with "empty password"
    else
      let password = fst !pwd_crypt_ref password in
      without_transaction @@ fun dbh ->
      [%pgsql
        dbh
          "UPDATE ocsigen_start.users SET password = $password
           WHERE userid = $userid"]

  let update_avatar ~userid ~avatar =
    without_transaction @@ fun dbh ->
    [%pgsql
      dbh
        "UPDATE ocsigen_start.users SET avatar = $avatar
         WHERE userid = $userid"]

  let update_main_email ~userid ~email =
    without_transaction @@ fun dbh ->
    [%pgsql
      dbh
        "UPDATE ocsigen_start.users u SET main_email = e.email
         FROM ocsigen_start.emails e
         WHERE e.email = $email AND u.userid = $userid
           AND e.userid = u.userid AND e.validated"]

  let update_language ~userid ~language =
    without_transaction @@ fun dbh ->
    [%pgsql
      dbh
        "UPDATE ocsigen_start.users SET language = $language
         WHERE userid = $userid"]

  let verify_password ~email ~password =
    if password = ""
    then Lwt.fail Empty_password
    else
      one without_transaction
        (fun dbh ->
          [%pgsql
            dbh
              "SELECT userid, password, validated
               FROM ocsigen_start.users
               JOIN ocsigen_start.emails USING (userid)
               WHERE email = $email"])
        ~success:(fun (userid, password', validated) ->
          (* We fail for non-validated e-mails,
             because we don't want the user to log in with a non-validated
             email address. For example if the sign-up form contains
             a password field. *)
          match password' with
          | Some password' when snd !pwd_crypt_ref userid password password' ->
              if validated
              then Lwt.return userid
              else Lwt.fail Account_not_activated
          | Some _ -> Lwt.fail Wrong_password
          | _ -> Lwt.fail Password_not_set)
        ~fail:(Lwt.fail No_such_user)

  let verify_password_phone ~number ~password =
    if password = ""
    then Lwt.fail Empty_password
    else
      one without_transaction
        (fun dbh ->
          [%pgsql
            dbh
              "SELECT userid, password
               FROM ocsigen_start.users
               JOIN ocsigen_start.phones USING (userid)
               WHERE number = $number"])
        ~success:(fun (userid, password') ->
          match password' with
          | Some password' when snd !pwd_crypt_ref userid password password' ->
              Lwt.return userid
          | Some _ -> Lwt.fail Wrong_password
          | _ -> Lwt.fail Password_not_set)
        ~fail:(Lwt.fail No_such_user)

  let user_of_userid userid =
    one without_transaction
      ~success:
        (fun
          (userid, firstname, lastname, avatar, has_password, language) ->
        Lwt.return
          ( userid
          , firstname
          , lastname
          , avatar
          , has_password = Some true
          , language ))
      ~fail:(Lwt.fail No_such_resource)
      (fun dbh ->
        [%pgsql
          dbh
            "SELECT userid, firstname, lastname, avatar,
                  password IS NOT NULL, language
           FROM ocsigen_start.users WHERE userid = $userid"])

  let get_actionlinkkey_info act_key =
    full_transaction_block (fun dbh ->
        one
          (fun q -> q dbh)
          ~fail:(Lwt.fail No_such_resource)
          (fun dbh ->
            [%pgsql
              dbh
                "SELECT userid, email, validity, expiry, autoconnect, action, data
               FROM ocsigen_start.activation
               WHERE activationkey = $act_key"])
          ~success:
            (fun (userid, email, validity, expiry, autoconnect, action, data) ->
            let action =
              match action with
              | "activation" -> `AccountActivation
              | "passwordreset" -> `PasswordReset
              | c -> `Custom c
            in
            let v = max 0L (Int64.pred validity) in
            let%lwt () =
              (* We provide a grace period of 20 seconds before expiring the
               key, in case the link is successively opened several times *)
              if v = 0L
              then
                [%pgsql
                  dbh
                    "UPDATE ocsigen_start.activation
                  SET expiry = LEAST(NOW() AT TIME ZONE 'utc'
                                     + INTERVAL '20 seconds',
                                     expiry)
                  WHERE activationkey = $act_key"]
              else
                [%pgsql
                  dbh
                    "UPDATE ocsigen_start.activation
                 SET validity = $v WHERE activationkey = $act_key"]
            in
            Lwt.return
              Os_types.Action_link_key.
                {userid; email; validity; expiry; action; data; autoconnect}))

  let emails_of_userid userid =
    without_transaction @@ fun dbh ->
    [%pgsql dbh "SELECT email FROM ocsigen_start.emails WHERE userid = $userid"]

  let emails_of_userid_with_status userid =
    without_transaction @@ fun dbh ->
    [%pgsql
      dbh
        "SELECT email, validated
         FROM ocsigen_start.emails WHERE userid = $userid"]

  let email_of_userid userid =
    one without_transaction
      ~success:(fun main_email -> Lwt.return main_email)
      ~fail:(Lwt.fail No_such_resource)
      (fun dbh ->
        [%pgsql
          dbh
            "SELECT main_email FROM ocsigen_start.users WHERE userid = $userid"])

  let is_main_email ~userid ~email =
    one without_transaction
      ~success:(fun _ -> Lwt.return_true)
      ~fail:Lwt.return_false
      (fun dbh ->
        [%pgsql
          dbh
            "SELECT 1 FROM ocsigen_start.users
            WHERE userid = $userid AND main_email = $email"])

  let add_email_to_user ~userid ~email =
    without_transaction @@ fun dbh ->
    [%pgsql
      dbh
        "INSERT INTO ocsigen_start.emails (email, userid)
         VALUES ($email, $userid)"]

  let remove_email_from_user ~userid ~email =
    let%lwt b = is_main_email ~userid ~email in
    if b
    then Lwt.fail Main_email_removal_attempt
    else
      without_transaction @@ fun dbh ->
      [%pgsql
        dbh
          "DELETE FROM ocsigen_start.emails
           WHERE userid = $userid AND email = $email"]

  let get_language userid =
    one without_transaction
      ~success:(fun language -> Lwt.return language)
      ~fail:(Lwt.fail No_such_resource)
      (fun dbh ->
        [%pgsql
          dbh "SELECT language FROM ocsigen_start.users WHERE userid = $userid"])

  let get_users ?pattern () =
    let%lwt l =
      without_transaction (fun dbh ->
          match pattern with
          | None ->
              [%pgsql
                dbh
                  "SELECT userid, firstname, lastname, avatar,
                       password IS NOT NULL, language
                FROM ocsigen_start.users"]
          | Some pattern ->
              let pattern = "(^" ^ pattern ^ ")|(.* " ^ pattern ^ ")" in
              [%pgsql
                dbh
                  "SELECT userid, firstname, lastname, avatar,
                      password IS NOT NULL, language
               FROM ocsigen_start.users
               WHERE firstname <> '' -- avoids email addresses
                 AND CONCAT_WS(' ', firstname, lastname) ~* $pattern"])
    in
    Lwt.return
      (List.map
         (fun (userid, firstname, lastname, avatar, has_password, language) ->
            ( userid
            , firstname
            , lastname
            , avatar
            , has_password = Some true
            , language ))
         l)
end

module Groups = struct
  let create ?description name =
    without_transaction @@ fun dbh ->
    [%pgsql
      dbh
        "INSERT INTO ocsigen_start.groups (description, name)
         VALUES ($?description, $name)
         ON CONFLICT DO NOTHING"]

  let group_of_name name =
    without_transaction (fun dbh ->
        [%pgsql
          dbh
            "SELECT groupid, name, description
           FROM ocsigen_start.groups WHERE name = $name"])
    >>= function
    | [r] -> Lwt.return r
    | _ -> Lwt.fail No_such_resource

  let add_user_in_group ~groupid ~userid =
    without_transaction @@ fun dbh ->
    [%pgsql
      dbh
        "INSERT INTO ocsigen_start.user_groups (userid, groupid)
         VALUES ($userid, $groupid)"]

  let remove_user_in_group ~groupid ~userid =
    without_transaction @@ fun dbh ->
    [%pgsql
      dbh
        "DELETE FROM ocsigen_start.user_groups
         WHERE groupid = $groupid AND userid = $userid"]

  let in_group ?dbh ~groupid ~userid () =
    one
      (match dbh with
      | None -> without_transaction
      | Some dbh -> fun f -> f dbh)
      ~success:(fun _ -> Lwt.return_true)
      ~fail:Lwt.return_false
      (fun dbh ->
        [%pgsql
          dbh
            "SELECT 1 FROM ocsigen_start.user_groups
           WHERE groupid = $groupid AND userid = $userid"])

  let all () =
    without_transaction @@ fun dbh ->
    [%pgsql dbh "SELECT groupid, name, description FROM ocsigen_start.groups"]
end

module Phone = struct
  let add userid number =
    without_transaction @@ fun dbh ->
    let%lwt l =
      [%pgsql
        dbh
          "INSERT INTO ocsigen_start.phones (number, userid)
           VALUES ($number, $userid)
           ON CONFLICT DO NOTHING
           RETURNING 0"]
    in
    Lwt.return (match l with [_] -> true | _ -> false)

  let exists number =
    match%lwt
      without_transaction @@ fun dbh ->
      [%pgsql dbh "SELECT 1 FROM ocsigen_start.phones WHERE number = $number"]
    with
    | _ :: _ -> Lwt.return_true
    | [] -> Lwt.return_false

  let userid number =
    match%lwt
      without_transaction @@ fun dbh ->
      [%pgsql
        dbh "SELECT userid FROM ocsigen_start.phones WHERE number = $number"]
    with
    | userid :: _ -> Lwt.return (Some userid)
    | [] -> Lwt.return None

  let delete userid number =
    without_transaction @@ fun dbh ->
    [%pgsql
      dbh
        "DELETE FROM ocsigen_start.phones
         WHERE userid = $userid AND number = $number"]

  let get_list userid =
    without_transaction @@ fun dbh ->
    [%pgsql
      dbh "SELECT number FROM ocsigen_start.phones WHERE userid = $userid"]
end
