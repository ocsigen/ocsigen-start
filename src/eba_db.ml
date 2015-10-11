(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
 *
 * Copyright (C) 2014
 *      Charly Chevalier
 *      Vincent Balat
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

exception No_such_resource
exception Cannot_delete_primary_mail

let (>>=) = Lwt.bind

module Lwt_thread = struct
  include Lwt
  include Lwt_chan
end
module Lwt_PGOCaml = PGOCaml_generic.Make(Lwt_thread)
module Lwt_Query_ = Query.Make_with_Db(Lwt_thread)(Lwt_PGOCaml)
module PGOCaml = Lwt_PGOCaml

let port = ref 3000
let db = ref "eba"
let host = ref "localhost"

let init ~port:p ~database ~db_host () =
  port := p;
  db := database;
  host := db_host

let connect () =
  Lwt_PGOCaml.connect ~host:!host ~port:!port ~database:!db ()

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

module Lwt_Query = struct
  include Lwt_Query_
  let view_one dbh rq =
    try_lwt
      view_one dbh rq
    with Failure _ -> Lwt.fail No_such_resource
end


(*****************************************************************************)
(* tables, for Macaque *)
let users_userid_seq = <:sequence< bigserial "users_userid_seq" >>

let users_table =
  <:table< users (
       userid bigint NOT NULL DEFAULT(nextval $users_userid_seq$),
       firstname text NOT NULL,
       lastname text NOT NULL,
       password text,
       avatar text
          ) >>

let emails_table =
  <:table< emails (
       email text NOT NULL,
       userid bigint NOT NULL,
       is_primary boolean NOT NULL,
       is_activated boolean NOT NULL
          ) >>

let activation_table :
  (< .. >,
   < creationdate : < nul : Sql.non_nullable; .. > Sql.t > Sql.writable)
    Sql.view =
  <:table< activation (
       activationkey text NOT NULL,
       email text NOT NULL,
       creationdate timestamptz NOT NULL DEFAULT(current_timestamp ())
           ) >>

let groups_groupid_seq = <:sequence< bigserial "groups_groupid_seq" >>

let groups_table =
  <:table< groups (
       groupid bigint NOT NULL DEFAULT(nextval $groups_groupid_seq$),
       name text NOT NULL,
       description text
          ) >>

let user_groups_table =
  <:table< user_groups (
       userid bigint NOT NULL,
       groupid bigint NOT NULL
          ) >>

let preregister_table =
  <:table< preregister (
       email text NOT NULL
          ) >>



(*****************************************************************************)

let pwd_crypt_ref = ref
    ((fun password -> Bcrypt.string_of_hash (Bcrypt.hash password)),
     (fun _ password1 password2 ->
        Bcrypt.verify password1 (Bcrypt.hash_of_string password2)))

module User = struct

  let select_user_from_email_q dbh email =
    lwt r = Lwt_Query.view_one dbh
      <:view< { t1.userid } |
              t1 in $users_table$;
              t2 in $emails_table$;
              t1.userid = t2.userid;
              t2.email = $string:email$;
      >>
    in
    Lwt.return (r#!userid)

  let is_registered email =
    full_transaction_block (fun dbh ->
      try_lwt
        lwt _ = select_user_from_email_q dbh email in
        Lwt.return true
      with No_such_resource -> Lwt.return false)

  let add_preregister email =
    full_transaction_block (fun dbh ->
      Lwt_Query.query dbh
        <:insert< $preregister_table$ := { email = $string:email$ } >>)

  let remove_preregister email =
    full_transaction_block (fun dbh ->
      Lwt_Query.query dbh
        <:delete< r in $preregister_table$ |
                  r.email = $string:email$ >>)

  let is_preregistered email =
    full_transaction_block (fun dbh ->
      try_lwt
        lwt _ =
          Lwt_Query.view_one dbh
            <:view< { r.email } |
              r in $preregister_table$;
              r.email = $string:email$;
            >>
        in Lwt.return true
      with No_such_resource -> Lwt.return false)

  let emails_and_params_of_userid_q userid dbh =
    Lwt_Query.view dbh
      <:view< { t.email; t.is_primary; t.is_activated } |
                t in $emails_table$;
                t.userid = $int64:userid$;
      >>

  let emails_and_params_of_userid userid =
    lwt res = full_transaction_block (emails_and_params_of_userid_q userid) in
    let fmt_res x = x#!email, x#!is_primary, x#!is_activated in
    Lwt.return (List.map fmt_res res)

  let activate_email email =
    full_transaction_block (fun dbh ->
        Lwt_Query.query dbh
          <:update< t in $emails_table$ :=
                   { is_activated = $bool:true$ } |
                    t.email = $string:email$
             >>)

  let add_email_to_user userid email =
    full_transaction_block (fun dbh ->
        Lwt_Query.query dbh
            <:insert< $emails_table$ :=
                 { email = $string:email$;
                   userid  = $int64:userid$;
                   is_primary = $bool:false$;
                   is_activated = $bool:false$}
            >>)

  let set_email_is_primary_q is_primary email dbh =
    Lwt_Query.query dbh
      <:update< t in $emails_table$ :=
               { is_primary = $bool:is_primary$ } |
                t.email = $string:email$
         >>
  (* Does not check whether the email is activated *)
  let update_users_primary_email dbh email =
    full_transaction_block (fun dbh ->
       lwt userid = select_user_from_email_q dbh email in
       lwt emails = emails_and_params_of_userid_q userid dbh in
       let primary = List.filter (fun x -> x#!is_primary) emails in
       lwt () =
           match primary with
           | [hd] -> set_email_is_primary_q false hd#!email dbh
           | _ -> Lwt.return_unit
       in
       set_email_is_primary_q true email dbh)

  let get_email_q dbh email =
    Lwt_Query.view_opt dbh
          <:view< t |
                  t in $emails_table$;
                  t.email = $string: email$;
          >>

  let delete_email email =
    full_transaction_block (fun dbh ->
        match_lwt (get_email_q dbh email) with
        | None -> Lwt.return_unit
        | Some r ->
           if r#!is_primary then Lwt.fail Cannot_delete_primary_mail
           else
            Lwt_Query.query dbh
            <:delete< t in $emails_table$ |
                      t.email = $string:email$ >>)

  let all ?(limit = 10L) () =
    full_transaction_block (fun dbh ->
      lwt l = Lwt_Query.query dbh
        <:select< { email = a.email } limit $int64:limit$ |
                  a in $preregister_table$;
        >>
      in
      Lwt.return (List.map (fun a -> a#!email) l))

  let create ?password ?avatar ~firstname ~lastname email =
    full_transaction_block (fun dbh ->
      let password_o =
        Eliom_lib.Option.map (fun password ->
          let password = (fst !pwd_crypt_ref) password in
          <:value< $string:password$ >>)
          password
      in
      lwt () =
        Lwt_Query.query dbh
          <:insert< $users_table$ :=
                    { userid    = users_table?userid;
                      firstname = $string:firstname$;
                      lastname  = $string:lastname$;
                      password  = of_option $password_o$;
                      avatar    = null
                    } >>
      in
      lwt userid =
        Lwt_Query.view_one dbh <:view< {x = currval $users_userid_seq$} >>
      in
      let userid = userid#!x in
      lwt () =
        Lwt_Query.query dbh
          <:insert< $emails_table$ :=
                      { email = $string:email$;
                        userid  = $int64:userid$;
                        is_primary = $bool:true$;
                        is_activated = $bool:true$}
            >>
      in
      lwt () = remove_preregister email in
      Lwt.return userid
    )

  let update ?password ?avatar ~firstname ~lastname userid =
    full_transaction_block (fun dbh ->
      (match password, avatar with
        | None, None ->
          Lwt_Query.query dbh
             <:update< d in $users_table$ :=
                      { firstname = $string:firstname$;
                        lastname = $string:lastname$ } |
                       d.userid = $int64:userid$
             >>
        | None, Some avatar ->
          let avatar = Some <:value< $string:avatar$ >> in
          Lwt_Query.query dbh
             <:update< d in $users_table$ :=
                      { firstname = $string:firstname$;
                        lastname = $string:lastname$;
                        avatar = of_option $avatar$ } |
                       d.userid = $int64:userid$
             >>
        | Some password, None ->
          let password = (fst !pwd_crypt_ref) password in
          let password = Some <:value< $string:password$ >> in
          Lwt_Query.query dbh
             <:update< d in $users_table$ :=
                      { firstname = $string:firstname$;
                        lastname = $string:lastname$;
                        password = of_option $password$ } |
                       d.userid = $int64:userid$
             >>
        | Some password, Some avatar ->
          let password = (fst !pwd_crypt_ref) password in
          let password = Some <:value< $string:password$ >> in
          let avatar = Some <:value< $string:avatar$ >> in
          Lwt_Query.query dbh
             <:update< d in $users_table$ :=
                      { firstname = $string:firstname$;
                        lastname = $string:lastname$;
                        avatar = of_option $avatar$;
                        password = of_option $password$
                       } |
                       d.userid = $int64:userid$
             >>
      ))

  let update_password password userid =
    full_transaction_block (fun dbh ->
      let password = (fst !pwd_crypt_ref) password in
      let password = Some <:value< $string:password$ >> in
      Lwt_Query.query dbh
        <:update< d in $users_table$ := { password = of_option $password$ }
                  | d.userid = $int64:userid$
        >>
    )

  let update_avatar avatar userid =
    full_transaction_block (fun dbh ->
      Lwt_Query.query dbh
        <:update< d in $users_table$ :=
                      { avatar = $string:avatar$ } |
                       d.userid = $int64:userid$
        >>
    )

  let add_activationkey ~act_key email =
    full_transaction_block (fun dbh ->
       Lwt_Query.query dbh
         <:insert< $activation_table$ :=
                      { email = $string:email$;
                        activationkey  = $string:act_key$;
                        creationdate = activation_table?creationdate }
         >>)

  let verify_password ~email ~password =
    full_transaction_block (fun dbh ->
      lwt r = Lwt_Query.view_one dbh
          <:view< { t1.userid; t1.password } |
                    t1 in $users_table$;
                    t2 in $emails_table$;
                    t1.userid = t2.userid;
                    t2.email = $string:email$;
            >>
      in
      let (userid, password') = (r#!userid, r#?password) in
      match password' with
      | None -> Lwt.fail No_such_resource
      | Some password' ->
          if (snd !pwd_crypt_ref) userid password password'
          then Lwt.return userid
          else Lwt.fail No_such_resource)

  let user_of_userid userid =
    full_transaction_block (fun dbh ->
      lwt r = Lwt_Query.view_one dbh
          <:view< t |
                  t in $users_table$;
                  t.userid = $int64:userid$
            >>
      in
      Lwt.return (r#!userid, r#!firstname, r#!lastname, r#?avatar,
                  r#?password <> None))

  let userid_of_activationkey act_key =
    full_transaction_block (fun dbh ->
      lwt r = Lwt_Query.view_opt dbh
          <:view< t |
                  t in $activation_table$;
                  t.activationkey = $string:act_key$
            >>
      in
      match r with
      | None -> Lwt.fail No_such_resource
      | Some r ->
        lwt userid = select_user_from_email_q dbh r#!email in
        lwt () = Lwt_Query.query dbh
            <:delete< r in $activation_table$ |
                      r.activationkey = $string:act_key$ >>
        in
        Lwt.return userid)

  let emails_of_userid userid =
    full_transaction_block (fun dbh ->
      lwt r = Lwt_Query.view dbh
          <:view< { t2.email } |
                    t1 in $users_table$;
                    t2 in $emails_table$;
                    t1.userid = t2.userid;
                    t1.userid = $int64:userid$;
            >>
      in
      Lwt.return (List.map (fun a -> a#!email) r))

  let email_of_userid userid =
    full_transaction_block (fun dbh ->
      lwt r = Lwt_Query.view dbh
          <:view< { t2.email } limit 1 |
                    t1 in $users_table$;
                    t2 in $emails_table$;
                    t1.userid = t2.userid;
                    t1.userid = $int64:userid$;
            >>
      in
      match r with
      | [a] -> Lwt.return a#!email
      | _ -> Lwt.fail No_such_resource)

  let userid_of_email email =
    full_transaction_block (fun dbh ->
      select_user_from_email_q dbh email)

  let get_users ?pattern () =
    full_transaction_block (fun dbh ->
      match pattern with
      | None ->
        lwt l = Lwt_Query.view dbh <:view< r | r in $users_table$ >> in
        Lwt.return (List.map
                      (fun a -> a#!userid, a#!firstname, a#!lastname, a#?avatar,
                                a#?password <> None)
                      l)
      | Some pattern ->
        let pattern = "(^"^pattern^")|(.* "^pattern^")" in
        (* Here I'm using the low-level pgocaml interface
           because macaque is missing some features
           and I canot use pgocaml syntax extension because
           it requires the db to be created (which is impossible in a lib). *)
        let query = "
             SELECT userid, firstname, lastname, avatar, password
             FROM users
             WHERE
               firstname <> '' -- avoids email addresses
             AND CONCAT_WS(' ', firstname, lastname) ~* $1
         "
        in
        lwt () = PGOCaml.prepare dbh ~query () in
        lwt l = PGOCaml.execute dbh [Some pattern] () in
        lwt () = PGOCaml.close_statement dbh () in
        Lwt.return (List.map
                      (function
                        | [Some userid; Some firstname; Some lastname; avatar;
                           password]
                          ->
                          (PGOCaml.int64_of_string userid,
                           firstname, lastname, avatar, password <> None)
                        | _ -> failwith "Eba_db.get_users")
                      l))

end

module Groups = struct
  let create ?description name =
    let description_o =
      Eliom_lib.Option.map (fun x -> <:value< $string:x$ >>) description
    in
    full_transaction_block (fun dbh ->
      Lwt_Query.query dbh
        <:insert< $groups_table$ :=
                      { description = of_option $description_o$;
                        name  = $string:name$;
                        groupid = groups_table?groupid }
         >>)

  let group_of_name name =
    full_transaction_block (fun dbh ->
      lwt r = Lwt_Query.view_opt dbh
          <:view< r |
                  r in $groups_table$;
                  r.name = $string:name$;
            >>
      in
      match r with
        | None -> Lwt.fail No_such_resource
        | Some r -> Lwt.return (r#!groupid, r#!name, r#?description))

  let add_user_in_group ~groupid ~userid =
    full_transaction_block (fun dbh ->
      Lwt_Query.query dbh
        <:insert< $user_groups_table$ :=
                      { userid = $int64:userid$;
                        groupid = $int64:groupid$ }
         >>)

  let remove_user_in_group ~groupid ~userid =
    full_transaction_block (fun dbh ->
      Lwt_Query.query dbh
        <:delete< r in $user_groups_table$ |
                  r.groupid = $int64:groupid$;
                  r.userid = $int64:userid$
        >>)

  let in_group ~groupid ~userid =
    full_transaction_block (fun dbh ->
      try_lwt
        lwt _ = Lwt_Query.view_one dbh
            <:view< t |
                    t in $user_groups_table$;
                    t.groupid = $int64:groupid$;
                    t.userid = $int64:userid$;
            >>
        in
        Lwt.return true
      with No_such_resource -> Lwt.return false)

  let all () =
    full_transaction_block (fun dbh ->
      lwt l = Lwt_Query.query dbh <:select< r | r in $groups_table$; >> in
      Lwt.return (List.map (fun a -> (a#!groupid, a#!name, a#?description)) l))


end
