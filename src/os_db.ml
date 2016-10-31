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

exception No_such_resource
exception Main_email_removal_attempt
exception Account_not_activated


let (>>=) = Lwt.bind

module Lwt_thread = struct
  include Lwt
  include Lwt_chan
end
module Lwt_PGOCaml = PGOCaml_generic.Make(Lwt_thread)
module Lwt_Query_ = Query.Make_with_Db(Lwt_thread)(Lwt_PGOCaml)
module PGOCaml = Lwt_PGOCaml

let host_r = ref None
let port_r = ref None
let user_r = ref None
let password_r = ref None
let database_r = ref None
let unix_domain_socket_dir_r = ref None

let connect () = Lwt_PGOCaml.connect
  ?host:!host_r
  ?port:!port_r
  ?user:!user_r
  ?password:!password_r
  ?database:!database_r
  ?unix_domain_socket_dir:!unix_domain_socket_dir_r
  ()

let validate db =
  try_lwt
    lwt () = Lwt_PGOCaml.ping db in
    Lwt.return true
  with _ ->
    Lwt.return false

let pool : (string, bool) Hashtbl.t Lwt_PGOCaml.t Lwt_pool.t ref =
  ref @@ Lwt_pool.create 16 ~validate connect

let set_pool_size n = pool := Lwt_pool.create n ~validate connect

let init ?host ?port ?user ?password ?database
         ?unix_domain_socket_dir ?pool_size () =
  host_r := host;
  port_r := port;
  user_r := user;
  password_r := password;
  database_r := database;
  unix_domain_socket_dir_r := unix_domain_socket_dir;
  match pool_size with
  | None -> ()
  | Some n -> set_pool_size n

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
  Lwt_pool.use !pool (fun db -> transaction_block db (fun () -> f db))

let without_transaction f = Lwt_pool.use !pool (fun db -> f db)

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
let os_users_userid_seq = <:sequence< bigserial "ocsigen_start.users_userid_seq" >>

let os_users_table =
  <:table< ocsigen_start.users (
       userid bigint NOT NULL DEFAULT(nextval $os_users_userid_seq$),
       firstname text NOT NULL,
       lastname text NOT NULL,
       main_email citext NOT NULL,
       password text,
       avatar text
          ) >>

let os_emails_table =
  <:table< ocsigen_start.emails (
       email citext NOT NULL,
       userid bigint NOT NULL,
       validated boolean NOT NULL DEFAULT(false)
          ) >>

let os_action_link_table :
  (< .. >,
   < creationdate : < nul : Sql.non_nullable; .. > Sql.t > Sql.writable)
    Sql.view =
  <:table< ocsigen_start.activation (
       activationkey text NOT NULL,
       userid bigint NOT NULL,
       email citext NOT NULL,
       autoconnect boolean NOT NULL,
       validity bigint NOT NULL,
       action text NOT NULL,
       data text NOT NULL,
       creationdate timestamptz NOT NULL DEFAULT(current_timestamp ())
           ) >>

let os_groups_groupid_seq = <:sequence< bigserial "ocsigen_start.groupid_seq" >>

let os_groups_table =
  <:table< ocsigen_start.groups (
       groupid bigint NOT NULL DEFAULT(nextval $os_groups_groupid_seq$),
       name text NOT NULL,
       description text
          ) >>

let os_user_groups_table =
  <:table< ocsigen_start.user_groups (
       userid bigint NOT NULL,
       groupid bigint NOT NULL
          ) >>

let os_preregister_table =
  <:table< ocsigen_start.preregister (
       email citext NOT NULL
          ) >>



(*****************************************************************************)

module Utils = struct

  let as_sql_string v = <:value< $string:v$>>

  let run_query q = full_transaction_block (fun dbh ->
    Lwt_Query.query dbh q)

  let run_view q = full_transaction_block (fun dbh ->
    Lwt_Query.view dbh q)

  let run_view_opt q = full_transaction_block (fun dbh ->
    Lwt_Query.view_opt dbh q)

  let one f ~success ~fail q =
    f q >>= function
    | r::_ -> success r
    | _ -> fail

  let all f ~success ~fail q =
    f q >>= function
    | [] -> fail
    | r -> success r

  let password_of d = <:value< $d$.password>>

  let avatar_of d = <:value< $d$.avatar>>

  let tupple_of_user_sql u =
    u#!userid, u#!firstname, u#!lastname, u#?avatar, u#?password <> None

end
open Utils

let pwd_crypt_ref = ref
    ((fun password -> Bcrypt.string_of_hash (Bcrypt.hash password)),
     (fun _ password1 password2 ->
        Bcrypt.verify password1 (Bcrypt.hash_of_string password2)))

module Email = struct

  let available email = one run_query
      ~success:(fun _ -> Lwt.return_false)
      ~fail:Lwt.return_true
      <:select< row
                | row in $os_emails_table$; row2 in $os_users_table$;
                row.email = $string:email$;
                row2.userid = row.userid;
                is_not_null (row2.password) || row.validated
      >>

end

module User = struct

  exception Invalid_action_link_key of Os_types.User.id

  let userid_of_email email = one run_view
    ~success:(fun u -> Lwt.return u#!userid)
    ~fail:(Lwt.fail No_such_resource)
    <:view< { t1.userid }
     | t1 in $os_users_table$;
       t2 in $os_emails_table$;
       t1.userid = t2.userid;
       t2.email = $string:email$
    >>

  let is_registered email =
    try_lwt
      lwt _ = userid_of_email email in
      Lwt.return_true
    with No_such_resource -> Lwt.return_false

  let is_email_validated userid email = one run_query
    ~success:(fun _ -> Lwt.return_true)
    ~fail:Lwt.return_false
    <:select< row |
      row in $os_emails_table$;
      row.userid = $int64:userid$;
      row.email  = $string:email$;
      row.validated
    >>

  let set_email_validated userid email = run_query
    <:update< e in $os_emails_table$ := {validated = $bool:true$}
     | e.userid = $int64:userid$;
       e.email  = $string:email$
    >>

  let add_actionlinkkey ?(autoconnect=false)
      ?(action=`AccountActivation) ?(data="") ?(validity=1L)
      ~act_key ~userid ~email () =
    let action = match action with
      | `AccountActivation -> "activation"
      | `PasswordReset -> "passwordreset"
      | `Custom s -> s in
    run_query
     <:insert< $os_action_link_table$ :=
      { userid = $int64:userid$;
        email  = $string:email$;
        action = $string:action$;
        autoconnect = $bool:autoconnect$;
        data   = $string:data$;
        validity = $int64:validity$;
        activationkey  = $string:act_key$;
        creationdate   = os_action_link_table?creationdate }
      >>


  let add_preregister email = run_query
  <:insert< $os_preregister_table$ := { email = $string:email$ } >>

  let remove_preregister email = run_query
    <:delete< r in $os_preregister_table$ | r.email = $string:email$ >>

  let is_preregistered email = one run_view
    ~success:(fun _ -> Lwt.return_true)
    ~fail:Lwt.return_false
    <:view< { r.email }
     | r in $os_preregister_table$;
       r.email = $string:email$ >>

  let all ?(limit = 10L) () = run_query
    <:select< { email = a.email } limit $int64:limit$
    | a in $os_preregister_table$;
    >> >>= fun l ->
    Lwt.return (List.map (fun a -> a#!email) l)

  let create ?password ?avatar ~firstname ~lastname email =
    if password = Some "" then Lwt.fail_with "empty password"
    else
      full_transaction_block (fun dbh ->
        let password_o = Eliom_lib.Option.map (fun p ->
          as_sql_string @@ fst !pwd_crypt_ref p) password
        in
        let avatar_o = Eliom_lib.Option.map as_sql_string avatar in
        lwt () = Lwt_Query.query dbh
          <:insert< $os_users_table$ :=
           { userid     = os_users_table?userid;
             firstname  = $string:firstname$;
             lastname   = $string:lastname$;
             main_email = $string:email$;
             password   = of_option $password_o$;
             avatar     = of_option $avatar_o$
            } >>
        in
        lwt userid = Lwt_Query.view_one dbh
          <:view< {x = currval $os_users_userid_seq$} >>
        in
        let userid = userid#!x in
        lwt () = Lwt_Query.query dbh
          <:insert< $os_emails_table$ :=
           { email = $string:email$;
             userid  = $int64:userid$;
             validated = os_emails_table?validated
           } >>
        in
        lwt () = remove_preregister email in
        Lwt.return userid
      )

  let update ?password ?avatar ~firstname ~lastname userid =
    if password = Some "" then Lwt.fail_with "empty password"
    else
      let password = match password with
        | Some password ->
          fun _ -> as_sql_string @@ fst !pwd_crypt_ref password
        | None ->
          password_of
      in
      let avatar = match avatar with
        | Some avatar ->
          fun _ -> as_sql_string avatar
        | None ->
          avatar_of
      in
      run_query <:update< d in $os_users_table$ :=
       { firstname = $string:firstname$;
         lastname = $string:lastname$;
         avatar = $avatar d$;
         password = $password d$
       } |
       d.userid = $int64:userid$
      >>

  let update_password ~userid ~password =
    if password = "" then Lwt.fail_with "empty password"
    else
      let password = as_sql_string @@ fst !pwd_crypt_ref password in
      run_query <:update< d in $os_users_table$ :=
        { password = $password$ }
        | d.userid = $int64:userid$
       >>

  let update_avatar ~userid ~avatar = run_query
    <:update< d in $os_users_table$ :=
     { avatar = $string:avatar$ }
     | d.userid = $int64:userid$
     >>

  let update_main_email ~userid ~email = run_query
    <:update< u in $os_users_table$ := { main_email = $string:email$ }
     | e in $os_emails_table$;
       e.email = $string:email$;
       u.userid = $int64:userid$;
       e.userid = u.userid;
       e.validated
    >>

  let verify_password ~email ~password =
    if password = "" then Lwt.fail No_such_resource
    else
      full_transaction_block (fun dbh ->
        lwt r = Lwt_Query.view_one dbh <:view<
              { t1.userid; t1.password; t2.validated }
                 | t1 in $os_users_table$;
                   t2 in $os_emails_table$;
                   t1.userid = t2.userid;
                   t2.email = $string:email$
             >>
       (* We fail for non-validated e-mails,
          because we don't want the user to log in with a non-validated
          email address. For example if the sign-up form contains
          a password field. *)
        in
        let (userid, password', validated) =
          (r#!userid, r#?password, r#!validated)
        in
        match password' with
        | Some password' when snd !pwd_crypt_ref userid password password' ->
          if validated then
            Lwt.return userid
          else
            Lwt.fail Account_not_activated
        | _ ->
          Lwt.fail No_such_resource
      )

  let user_of_userid userid = one run_view
    ~success:(fun r -> Lwt.return @@ tupple_of_user_sql r)
    ~fail:(Lwt.fail No_such_resource)
    <:view< t | t in $os_users_table$; t.userid = $int64:userid$ >>

  let get_actionlinkkey_info act_key =
    full_transaction_block (fun dbh ->
      one (Lwt_Query.view dbh)
        ~fail:(Lwt.fail No_such_resource)
        <:view< t
                | t in $os_action_link_table$;
                t.activationkey = $string:act_key$ >>
        ~success:(fun t ->
          let userid = t#!userid in
          let email  = t#!email in
          let validity = t#!validity in
          let autoconnect = t#!autoconnect in
          let action = match t#!action with
            | "activation" -> `AccountActivation
            | "passwordreset" -> `PasswordReset
            | c -> `Custom c in
          let data = t#!data in
          let v  = max 0L (Int64.pred validity) in
          lwt () = Lwt_Query.query dbh
              <:update< r in $os_action_link_table$ := {validity = $int64:v$} |
                        r.activationkey = $string:act_key$ >>
          in
          Lwt.return
            Os_types.Action_link_key.{
              userid;
              email;
              validity;
              action;
              data;
              autoconnect
            }
        )
    )

  let emails_of_userid userid = Utils.all run_view
    ~success:(fun r -> Lwt.return @@ List.map (fun a -> a#!email) r)
    ~fail:(Lwt.fail No_such_resource)
    <:view< { t2.email }
     | t1 in $os_users_table$;
       t2 in $os_emails_table$;
       t1.userid = t2.userid;
       t1.userid = $int64:userid$;
    >>

  let email_of_userid userid = one run_view
    ~success:(fun u -> Lwt.return u#!main_email)
    ~fail:(Lwt.fail No_such_resource)
    <:view< { u.main_email }
     | u in $os_users_table$;
       u.userid = $int64:userid$
    >>

   let is_main_email ~userid ~email = one run_view
     ~success:(fun _ -> Lwt.return_true)
     ~fail:Lwt.return_false
     <:view< { u.main_email }
      | u in $os_users_table$;
        u.userid = $int64:userid$;
        u.main_email = $string:email$
     >>

  let add_email_to_user ~userid ~email = run_query
    <:insert< $os_emails_table$ :=
      { email = $string:email$;
        userid  = $int64:userid$;
        validated = os_emails_table?validated
      } >>

  let remove_email_from_user ~userid ~email =
    lwt b = is_main_email ~userid ~email in
    if b then Lwt.fail Main_email_removal_attempt else
      run_query
        <:delete< e in $os_emails_table$
         | u in $os_users_table$;
           u.userid = $int64:userid$;
           e.userid = u.userid;
           e.email = $string:email$
        >>


  let get_users ?pattern () =
    full_transaction_block (fun dbh ->
      match pattern with
      | None ->
        lwt l = Lwt_Query.view dbh <:view< r | r in $os_users_table$ >> in
        Lwt.return @@ List.map tupple_of_user_sql l
      | Some pattern ->
        let pattern = "(^"^pattern^")|(.* "^pattern^")" in
        (* Here I'm using the low-level pgocaml interface
           because macaque is missing some features
           and I canot use pgocaml syntax extension because
           it requires the db to be created (which is impossible in a lib). *)
        let query = "
             SELECT userid, firstname, lastname, avatar, password
             FROM ocsigen_start.users
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
                        | _ -> failwith "Os_db.get_users")
                      l))

end

module Groups = struct
  let create ?description name =
    let description_o = Eliom_lib.Option.map as_sql_string description in
    run_query <:insert< $os_groups_table$ :=
                { description = of_option $description_o$;
                  name  = $string:name$;
                 groupid = os_groups_table?groupid }
               >>

  let group_of_name name = run_view_opt
    <:view< r | r in $os_groups_table$; r.name = $string:name$ >> >>= function
    | Some r -> Lwt.return (r#!groupid, r#!name, r#?description)
    | None -> Lwt.fail No_such_resource

  let add_user_in_group ~groupid ~userid = run_query
    <:insert< $os_user_groups_table$ :=
             { userid  = $int64:userid$;
               groupid = $int64:groupid$ }
    >>

  let remove_user_in_group ~groupid ~userid = run_query
    <:delete< r in $os_user_groups_table$ |
              r.groupid = $int64:groupid$;
              r.userid  = $int64:userid$
    >>

  let in_group ~groupid ~userid = one run_view
    ~success:(fun _ -> Lwt.return_true)
    ~fail:Lwt.return_false
    <:view< t | t in $os_user_groups_table$;
                t.groupid = $int64:groupid$;
                t.userid  = $int64:userid$;
    >>

  let all () = run_query <:select< r | r in $os_groups_table$; >> >>= fun l ->
    Lwt.return @@ List.map (fun a -> (a#!groupid, a#!name, a#?description)) l

end
