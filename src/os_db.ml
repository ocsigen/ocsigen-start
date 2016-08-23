(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
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

let init ?host ?port ?user ?password ?database ?unix_domain_socket_dir () =
  host_r := host;
  port_r := port;
  user_r := user;
  password_r := password;
  database_r := database;
  unix_domain_socket_dir_r := unix_domain_socket_dir

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
       email citext NOT NULL,
       userid bigint NOT NULL,
       validated boolean NOT NULL DEFAULT(false)
          ) >>

let activation_table :
  (< .. >,
   < creationdate : < nul : Sql.non_nullable; .. > Sql.t > Sql.writable)
    Sql.view =
  <:table< activation (
       activationkey text NOT NULL,
       userid bigint NOT NULL,
       email citext NOT NULL,
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
       email citext NOT NULL
          ) >>



(*****************************************************************************)

module Utils = struct

  let ( => ) v (f, g) = match v with
    | Some v -> f v
    | None -> g v

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
     | row in $emails_table$;
       row.email = $string:email$;
       row.validated
    >>

end

module User = struct

  let userid_of_email email = one run_view
    ~success:(fun u -> Lwt.return u#!userid)
    ~fail:(Lwt.fail No_such_resource)
    <:view< { t1.userid }
     | t1 in $users_table$;
       t2 in $emails_table$;
       t1.userid = t2.userid;
       t2.email = $string:email$
    >>

  let is_registered email =
    try_lwt
      lwt _ = userid_of_email email in
      Lwt.return_true
    with No_such_resource -> Lwt.return_false

  let get_email_validated userid email = one run_query
    ~success:(fun _ -> Lwt.return_true)
    ~fail:Lwt.return_false
    <:select< row |
      row in $emails_table$;
      row.userid = $int64:userid$;
      row.email  = $string:email$;
      row.validated
    >>

  let set_email_validated userid email = run_query
    <:update< e in $emails_table$ := {validated = $bool:true$}
     | e.userid = $int64:userid$;
       e.email  = $string:email$
    >>

  let add_activationkey ~act_key ~userid ~email = run_query
     <:insert< $activation_table$ :=
      { userid = $int64:userid$;
        email  = $string:email$;
        activationkey  = $string:act_key$;
        creationdate   = activation_table?creationdate }
      >>

  let add_preregister email = run_query
  <:insert< $preregister_table$ := { email = $string:email$ } >>

  let remove_preregister email = run_query
    <:delete< r in $preregister_table$ | r.email = $string:email$ >>

  let is_preregistered email = one run_view
    ~success:(fun _ -> Lwt.return_true)
    ~fail:Lwt.return_false
    <:view< { r.email }
     | r in $preregister_table$;
       r.email = $string:email$ >>

  let all ?(limit = 10L) () = run_query
    <:select< { email = a.email } limit $int64:limit$
    | a in $preregister_table$;
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
	  <:insert< $users_table$ :=
           { userid    = users_table?userid;
             firstname = $string:firstname$;
             lastname  = $string:lastname$;
             password  = of_option $password_o$;
             avatar    = of_option $avatar_o$
            } >>		      
	in
        lwt userid = Lwt_Query.view_one dbh
	  <:view< {x = currval $users_userid_seq$} >>
        in
	let userid = userid#!x in
	lwt () = Lwt_Query.query dbh
	  <:insert< $emails_table$ :=
           { email = $string:email$;
             userid  = $int64:userid$;
             validated = emails_table?validated
           } >>
	in
	lwt () = remove_preregister email in
	Lwt.return userid
      )

  let update ?password ?avatar ~firstname ~lastname userid =
    if password = Some "" then Lwt.fail_with "empty password"
    else
      let password = password => (
	(fun p _ -> as_sql_string @@ fst !pwd_crypt_ref p),
	(fun _ -> password_of)
      ) in
      let avatar = avatar => (
	(fun a _ -> as_sql_string a),
	(fun _ -> avatar_of)
      ) in
      run_query <:update< d in $users_table$ :=
       { firstname = $string:firstname$;
         lastname = $string:lastname$;
         avatar = $avatar d$;
         password = $password d$
       } |
       d.userid = $int64:userid$
      >>

  let update_password password userid =
    if password = "" then Lwt.fail_with "empty password"
    else
      let password = as_sql_string @@ fst !pwd_crypt_ref password in
      run_query <:update< d in $users_table$ :=
        { password = $password$ }
        | d.userid = $int64:userid$
       >>

  let update_avatar avatar userid = run_query
    <:update< d in $users_table$ :=
     { avatar = $string:avatar$ }
     | d.userid = $int64:userid$
     >>

   let verify_password ~email ~password =
     if password = "" then Lwt.fail No_such_resource
     else
       full_transaction_block (fun dbh ->
	 lwt r = Lwt_Query.view_one dbh <:view< { t1.userid; t1.password }
                 | t1 in $users_table$;
                   t2 in $emails_table$;
                   t1.userid = t2.userid;
                   t2.email = $string:email$;
                   t2.validated
             >>
       (* We fail for non-validated e-mails,
          because we don't want the user to log in with a non-validated
          email address. For example if the sign-up form contains
          a password field. *)
	 in
	 let (userid, password') = (r#!userid, r#?password) in
	 match password' with
	 | Some password' when snd !pwd_crypt_ref userid password password' ->
           Lwt.return userid
	 | _ ->
	   Lwt.fail No_such_resource
       )

  let user_of_userid userid = one run_view
    ~success:(fun r -> Lwt.return @@ tupple_of_user_sql r)
    ~fail:(Lwt.fail No_such_resource)
    <:view< t | t in $users_table$; t.userid = $int64:userid$ >>

  let userid_and_email_of_activationkey act_key =
    full_transaction_block (fun dbh ->
      one (Lwt_Query.view dbh)
	~fail:(Lwt.fail No_such_resource)
        <:view< t 
         | t in $activation_table$;
           t.activationkey = $string:act_key$ >>
	~success:(fun t ->
	  let userid = t#!userid in
	  let email  = t#!email in
	  lwt () = Lwt_Query.query dbh
	   <:delete< r in $activation_table$
            | r.activationkey = $string:act_key$ >>
	  in
	  Lwt.return (userid, email)
       )
    )

  let emails_of_userid userid = Utils.all run_view
    ~success:(fun r -> Lwt.return @@ List.map (fun a -> a#!email) r)
    ~fail:(Lwt.fail No_such_resource)
    <:view< { t2.email }
     | t1 in $users_table$;
       t2 in $emails_table$;
       t1.userid = t2.userid;
       t1.userid = $int64:userid$;
    >>

  let email_of_userid userid = one run_view
    ~success:(fun e -> Lwt.return e#!email)
    ~fail:(Lwt.fail No_such_resource)
    <:view< { t2.email } limit 1
     | t1 in $users_table$;
       t2 in $emails_table$;
       t1.userid = t2.userid;
       t1.userid = $int64:userid$;
    >>

  let add_mail_to_user userid email = run_query
    <:insert< $emails_table$ :=
      { email = $string:email$;
        userid  = $int64:userid$;
        validated = emails_table?validated
      } >>

  let get_users ?pattern () =
    full_transaction_block (fun dbh ->
      match pattern with
      | None ->
        lwt l = Lwt_Query.view dbh <:view< r | r in $users_table$ >> in
	Lwt.return @@ List.map tupple_of_user_sql l
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
                        | _ -> failwith "Os_db.get_users")
                      l))

end

module Groups = struct
  let create ?description name =
    let description_o = Eliom_lib.Option.map as_sql_string description in
    run_query <:insert< $groups_table$ :=
                { description = of_option $description_o$;
                  name  = $string:name$;
                 groupid = groups_table?groupid }
               >>

  let group_of_name name = run_view_opt
    <:view< r | r in $groups_table$; r.name = $string:name$ >> >>= fun r ->
    r => ((fun r -> Lwt.return (r#!groupid, r#!name, r#?description)),
	  (fun _ -> Lwt.fail No_such_resource))

  let add_user_in_group ~groupid ~userid = run_query
    <:insert< $user_groups_table$ :=
             { userid  = $int64:userid$;
               groupid = $int64:groupid$ }
    >>

  let remove_user_in_group ~groupid ~userid = run_query
    <:delete< r in $user_groups_table$ |
              r.groupid = $int64:groupid$;
              r.userid  = $int64:userid$
    >>

  let in_group ~groupid ~userid = one run_view
    ~success:(fun _ -> Lwt.return_true)
    ~fail:Lwt.return_false
    <:view< t | t in $user_groups_table$;
                t.groupid = $int64:groupid$;
                t.userid  = $int64:userid$;
    >>

  let all () = run_query <:select< r | r in $groups_table$; >> >>= fun l ->
    Lwt.return @@ List.map (fun a -> (a#!groupid, a#!name, a#?description)) l

end
