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

class type config = object
  method name : string
  method port : int
  method workers : int

  method hash : string -> string
  method verify : string -> string -> bool
end

module type User_T = sig
  type t =
    < firstname : < get : unit; nul : Sql.non_nullable; t : Sql.string_t > Sql.t;
      lastname : < get : unit; nul : Sql.non_nullable; t : Sql.string_t > Sql.t;
      pic : < get : unit; nul : Sql.nullable; t : Sql.string_t > Sql.t;
      pwd : < get : unit; nul : Sql.nullable; t : Sql.string_t > Sql.t;
      userid : < get : unit; nul : Sql.non_nullable; t : Sql.int64_t > Sql.t
    >

  module Q : sig
    val does_mail_exist : 'a Lwt_Query.Db.t -> string -> int64 option Lwt.t
  end

  val new_user : ?avatar:string -> string -> int64 Lwt.t

  val does_mail_exist : string -> int64 option Lwt.t
  val does_activationkey_exist : string -> int64 option Lwt.t
  val does_uid_exist : int64 -> t option Lwt.t

  val verify_password : string -> string -> int64 Lwt.t

  val set : int64
            -> ?act_key:string
            -> ?firstname:string
            -> ?lastname:string
            -> ?password:string
            -> ?avatar:string
            -> unit
            -> unit Lwt.t

  val get_users_from_name : (string * string) -> t list Lwt.t
  val get_userslist : unit -> t list Lwt.t
  (*val get_pic : int64 -> string option Lwt.t*)
end

module type Groups_T = sig
  type t =
    < description : < get : unit; nul : Sql.nullable; t : Sql.string_t > Sql.t;
      groupid : < get : unit; nul : Sql.non_nullable; t : Sql.int64_t > Sql.t;
      name : < get : unit; nul : Sql.non_nullable; t : Sql.string_t > Sql.t;
    >

  module Q : sig
    val does_group_exist : 'a Lwt_Query.Db.t -> string -> t option Lwt.t
    val is_user_in_group : 'a Lwt_Query.Db.t -> userid:int64 -> groupid:int64 -> bool Lwt.t
  end

  val get_group : string -> t Lwt.t
  val new_group : ?description:string -> string -> unit Lwt.t

  val is_user_in_group : userid:int64 -> groupid:int64 -> bool Lwt.t
  val add_user_in_group : userid:int64 -> groupid:int64 -> unit Lwt.t
  val remove_user_in_group : userid:int64 -> groupid:int64 -> unit Lwt.t

  val does_group_exist : string -> t option Lwt.t
  val all_groups : unit -> t list Lwt.t
end

module type Egroups_T = sig
  type t =
    < description : < get : unit; nul : Sql.nullable; t : Sql.string_t > Sql.t;
      groupid : < get : unit; nul : Sql.non_nullable; t : Sql.int64_t > Sql.t;
      name : < get : unit; nul : Sql.non_nullable; t : Sql.string_t > Sql.t;
    >

  module Q : sig
    val does_egroup_exist : 'a Lwt_Query.Db.t -> string -> t option Lwt.t
    val is_email_in_egroup : 'a Lwt_Query.Db.t -> email:string -> egroupid:int64 -> bool Lwt.t
  end

  val get_egroup : string -> t Lwt.t
  val new_egroup : ?description:string -> string -> unit Lwt.t

  val is_email_in_egroup : email:string -> egroupid:int64 -> bool Lwt.t
  val add_email_in_egroup : email:string -> egroupid:int64 -> unit Lwt.t
  val remove_email_in_egroup : email:string -> egroupid:int64 -> unit Lwt.t

  val does_egroup_exist : string -> t option Lwt.t
  val get_emails_in_egroup : egroupid:int64 -> n:int -> string list Lwt.t
  val all_egroups : unit -> t list Lwt.t
end


module type T = sig
  module User : User_T
  module U : User_T

  module Groups : Groups_T
  module G : Groups_T

  module Egroups : Egroups_T
  module Eg : Egroups_T
end

module Make(M : sig
  val config : config
end)
=
struct
  let connect () =
    Lwt_PGOCaml.connect
      ~port:M.config#port
      ~database:M.config#name
      ()

  let validate db =
    try_lwt
      lwt () = Lwt_PGOCaml.ping db in
      Lwt.return true
    with _ ->
      Lwt.return false

  let pool : (string, bool) Hashtbl.t Lwt_PGOCaml.t Lwt_pool.t =
    Lwt_pool.create M.config#workers ~validate connect

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
         (* 0 = user, 1 = beta testeur, 2 = admin *)
         (* there is not default value because it doesn't work with macaque *)
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

  let egroups_table_id_seq = <:sequence< bigserial "egroups_groupid_seq" >>

  let egroups_table = <:table< egroups (
         groupid bigint NOT NULL DEFAULT(nextval $egroups_table_id_seq$),
         name text NOT NULL,
         description text
  ) >>

  let email_egroups_table = <:table< email_egroups (
         email text NOT NULL,
         groupid bigint NOT NULL
  ) >>

  module User = struct

    type t =
      < firstname : < get : unit; nul : Sql.non_nullable; t : Sql.string_t > Sql.t;
        lastname : < get : unit; nul : Sql.non_nullable; t : Sql.string_t > Sql.t;
        userid : < get : unit; nul : Sql.non_nullable; t : Sql.int64_t > Sql.t;
        pwd : < get : unit; nul : Sql.nullable; t : Sql.string_t > Sql.t;
        pic : < get : unit; nul : Sql.nullable; t : Sql.string_t > Sql.t;
      >

    module Q = struct
      let does_mail_exist dbh email =
        try_lwt
          lwt e =
            Lwt_Query.view_one dbh
              <:view< e | e in $emails_table$;
                          e.email = $string:email$ >>
          in
          Lwt.return (Some e#!userid)
        with _ -> Lwt.return None
    end

    let new_user ?avatar m =
      full_transaction_block
        (fun dbh ->
           lwt () =
             match avatar with
               | Some avatar ->
                 Lwt_Query.query dbh
                   <:insert< $users_table$ := { userid = users_table?userid;
                                                firstname = $string:""$;
                                                lastname = $string:m$;
                                                pwd = $Sql.Op.null$;
                                                pic = $string:avatar$;
                                              } >>
             | None ->
                 (* Do not put a default pic otherwise it will be cancelled
                  when the user upload a new pic. *)
                 Lwt_Query.query dbh
                   <:insert< $users_table$ := { userid = users_table?userid;
                                                firstname = $string:""$;
                                                lastname = $string:m$;
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
           lwt () =
             Lwt_Query.query dbh
               <:insert< $emails_table$ := { email = $string:m$;
                                             userid = $int64:userid$
                                           } >>
           in
           (*lwt () = create_activation_key dbh userid key in*)
           Lwt.return userid)

    let does_uid_exist uid =
      full_transaction_block
        (fun dbh ->
           try_lwt
             lwt u =
               Lwt_Query.view_one dbh
                 <:view< r | r in $users_table$;
                             r.userid = $int64:uid$ >>
             in
             Lwt.return (Some u)
           with
             | _ -> Lwt.return None)


    let password_view =
      <:view< { email = e.email; pwd = u.pwd; userid=u.userid }
                | u in $users_table$;
                  e in $emails_table$;
                  u.userid = e.userid >>

    let verify_password login pwd =
      full_transaction_block
      (fun dbh ->
        lwt l =
          Lwt_Query.query dbh
            <:select< r | r in $password_view$;
                          r.email = $string:login$ >>
                       (* r.pwd = $string:pwd$ >> *)
        in
        match l with
          | [] -> Lwt.fail Not_found
          | [r] ->
              (match Sql.getn r#pwd with
                 | None -> Lwt.fail Not_found
                 | Some h ->
                     if M.config#verify pwd h
                     then Lwt.return (r#!userid)
                     else Lwt.fail Not_found)
          | r::_ ->
              Ocsigen_messages.warning "Db.check_pwd: should not occure. Check!";
              Lwt.return (r#!userid))


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

    let does_mail_exist m =
      full_transaction_block
        (fun dbh ->
          Q.does_mail_exist dbh m)

    (** Returns the userid corresponding to an activation key,
        and remove the activation key. *)
    let does_activationkey_exist act_key =
      full_transaction_block
        (fun dbh ->
           try_lwt
             lwt e =
               Lwt_Query.view_one dbh
                 <:view< e |
                         e in $activation_table$;
                         e.activationkey = $string:act_key$ >>
             in
             lwt () =
               Lwt_Query.query dbh
                 <:delete< r in $activation_table$ |
                           r.activationkey = $string:act_key$ >>
             in
             Lwt.return (Some (e#!userid))
           with Failure _ -> Lwt.return None)

    let set uid ?act_key ?firstname ?lastname ?password ?avatar () =
      full_transaction_block
        (fun dbh ->
           lwt () =
             match act_key with
               | None -> Lwt.return ()
               | Some act_key ->
                   (Lwt_Query.query dbh
                      <:insert< $activation_table$ := { activationkey = $string:act_key$;
                                                        userid = $int64:uid$;
                                                        creationdate = activation_table?creationdate
                                                      } >>)

           in
           let password =
             match password with
               | None -> None
               | Some p -> Some (M.config#hash p)
           in
           match firstname,lastname,password,avatar with
             | None, None, None, None -> Lwt.return ()
             | Some fn, None, None, None ->
                 (Lwt_Query.query dbh
                    <:update< u in $users_table$ := { firstname = $string:fn$;
                                                    } | u.userid = $int64:uid$ >>)
             | None, Some ln, None, None ->
                 (Lwt_Query.query dbh
                    <:update< u in $users_table$ := { lastname = $string:ln$;
                                                    } | u.userid = $int64:uid$ >>)
             | None, None, Some p, None ->
                 (Lwt_Query.query dbh
                    <:update< u in $users_table$ := { pwd = $string:p$;
                                                    } | u.userid = $int64:uid$ >>)
             | None, None, None, Some a ->
                 (Lwt_Query.query dbh
                    <:update< u in $users_table$ := { pic = $string:a$;
                                                    } | u.userid = $int64:uid$ >>)
             | Some fn, Some ln, None, None ->
                 (Lwt_Query.query dbh
                    <:update< u in $users_table$ := { firstname = $string:fn$;
                                                      lastname = $string:ln$;
                                                    } | u.userid = $int64:uid$ >>)
             | Some fn, None, Some p, None ->
                 (Lwt_Query.query dbh
                    <:update< u in $users_table$ := { firstname = $string:fn$;
                                                      pwd = $string:p$;
                                                    } | u.userid = $int64:uid$ >>)
             | Some fn, None, None, Some a ->
                 (Lwt_Query.query dbh
                    <:update< u in $users_table$ := { firstname = $string:fn$;
                                                      pic = $string:a$;
                                                    } | u.userid = $int64:uid$ >>)
             | Some fn, Some ln, Some p, None ->
                 (Lwt_Query.query dbh
                    <:update< u in $users_table$ := { firstname = $string:fn$;
                                                      lastname = $string:ln$;
                                                      pwd = $string:p$;
                                                    } | u.userid = $int64:uid$ >>)
             | Some fn, Some ln, None, Some a ->
                 (Lwt_Query.query dbh
                    <:update< u in $users_table$ := { firstname = $string:fn$;
                                                      lastname = $string:ln$;
                                                      pic = $string:a$;
                                                    } | u.userid = $int64:uid$ >>)
             | Some fn, None, Some p, Some a ->
                 (Lwt_Query.query dbh
                    <:update< u in $users_table$ := { firstname = $string:fn$;
                                                      pwd = $string:p$;
                                                      pic = $string:a$;
                                                    } | u.userid = $int64:uid$ >>)
             | None, Some ln, Some p, Some a ->
                 (Lwt_Query.query dbh
                    <:update< u in $users_table$ := { lastname = $string:ln$;
                                                      pwd = $string:p$;
                                                      pic = $string:a$;
                                                    } | u.userid = $int64:uid$ >>)
             | None, Some ln, Some p, None ->
                 (Lwt_Query.query dbh
                    <:update< u in $users_table$ := { lastname = $string:ln$;
                                                      pwd = $string:p$;
                                                    } | u.userid = $int64:uid$ >>)
             | None, Some ln, None, Some a ->
                 (Lwt_Query.query dbh
                    <:update< u in $users_table$ := { lastname = $string:ln$;
                                                      pic = $string:a$;
                                                    } | u.userid = $int64:uid$ >>)
             | None, None, Some p, Some a ->
                 (Lwt_Query.query dbh
                    <:update< u in $users_table$ := { pwd = $string:p$;
                                                      pic = $string:a$;
                                                    } | u.userid = $int64:uid$ >>)
             | Some fn, Some ln, Some p, Some a ->
                 (Lwt_Query.query dbh
                    <:update< u in $users_table$ := { firstname = $string:fn$;
                                                      lastname = $string:ln$;
                                                      pwd = $string:p$;
                                                      pic = $string:a$;
                                                    } | u.userid = $int64:uid$ >>))

    let get_userslist () =
      full_transaction_block
        (fun dbh ->
          Lwt_Query.query dbh <:select< r | r in $users_table$ >>)

  end

  module U = User

  module Groups = struct

    type t =
      < description : < get : unit; nul : Sql.nullable; t : Sql.string_t > Sql.t;
        groupid : < get : unit; nul : Sql.non_nullable; t : Sql.int64_t > Sql.t;
        name : < get : unit; nul : Sql.non_nullable; t : Sql.string_t > Sql.t;
      >

    module Q = struct

      let does_group_exist dbh name =
        try_lwt
          lwt g = Lwt_Query.view_one dbh
            <:view< g | g in $groups_table$;
                        g.name = $string:name$ >>;
          in
          Lwt.return (Some g)
        with _ -> Lwt.return None


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
           Lwt_Query.view_one dbh
             <:view< g | g in $groups_table$;
                         g.name = $string:name$ >>)

    let new_group ?description name =
      full_transaction_block
        (fun dbh ->
           try_lwt
             match description with
               | None ->
                   Lwt_Query.query dbh
                     <:insert< $groups_table$ := { groupid = groups_table?groupid;
                                                   name = $string:name$;
                                                   description = $Sql.Op.null$ } >>
               | Some d ->
                   Lwt_Query.query dbh
                     <:insert< $groups_table$ := { groupid = groups_table?groupid;
                                                   name = $string:name$;
                                                   description = $string:d$ }
                     >>
           with _ -> Lwt.return ())

    (* CHARLY: better to user label because we're going to user same
     * type for both and we don't want to make some mistakes :) *)
    let is_user_in_group ~userid ~groupid =
      full_transaction_block
        (fun dbh ->
           Q.is_user_in_group dbh ~userid ~groupid)

    (* CHARLY: same here *)
    let add_user_in_group ~userid ~groupid =
      full_transaction_block
        (fun dbh ->
           lwt b = Q.is_user_in_group dbh ~userid ~groupid in
           (* true -> in the group, false -> not in the group *)
           if b
           (* we don't need to add user to the groups because he already belongs to it *)
           then Lwt.return ()
           (* here, ew add the user to a group *)
           else
             Lwt_Query.query dbh
               <:insert< $user_groups_table$ := { userid = $int64:userid$;
                                                  groupid = $int64:groupid$ }
               >>)

    (* CHARLY: same here *)
    let remove_user_in_group ~userid ~groupid =
      full_transaction_block
        (fun dbh ->
           Lwt_Query.query dbh
             <:delete< ug in $user_groups_table$
                       | ug.userid = $int64:userid$;
                         ug.groupid = $int64:groupid$;
             >>)

    let does_group_exist name =
      full_transaction_block
        (fun dbh ->
           Q.does_group_exist dbh name)

    let all_groups () =
      full_transaction_block
        (fun dbh ->
           Lwt_Query.query dbh
             <:select< g | g in $groups_table$ >>)

  end

  module G = Groups

  module Egroups = struct

    type t =
      < description : < get : unit; nul : Sql.nullable; t : Sql.string_t > Sql.t;
        groupid : < get : unit; nul : Sql.non_nullable; t : Sql.int64_t > Sql.t;
        name : < get : unit; nul : Sql.non_nullable; t : Sql.string_t > Sql.t;
      >

    module Q = struct

      let does_egroup_exist dbh name =
        try_lwt
          lwt g = Lwt_Query.view_one dbh
            <:view< g | g in $egroups_table$;
                        g.name = $string:name$ >>;
          in
          Lwt.return (Some g)
        with _ -> Lwt.return None


      let is_email_in_egroup dbh ~email ~egroupid =
        try_lwt
          lwt _ = Lwt_Query.view_one dbh
            <:view< ug | ug in $email_egroups_table$;
                         ug.email = $string:email$;
                         ug.groupid = $int64:egroupid$;
            >>
          in Lwt.return true
        with _ -> Lwt.return false
    end

    let get_egroup name =
      full_transaction_block
        (fun dbh ->
           Lwt_Query.view_one dbh
             <:view< g | g in $egroups_table$;
                         g.name = $string:name$ >>)

    let new_egroup ?description name =
      full_transaction_block
        (fun dbh ->
           try_lwt
             match description with
               | None ->
                   Lwt_Query.query dbh
                     <:insert< $egroups_table$ := { groupid = egroups_table?groupid;
                                                            name = $string:name$;
                                                            description = $Sql.Op.null$ } >>
               | Some d ->
                   Lwt_Query.query dbh
                     <:insert< $egroups_table$ := { groupid = egroups_table?groupid;
                                                   name = $string:name$;
                                                   description = $string:d$ }
                     >>
           with _ -> Lwt.return ())

    (* CHARLY: better to user label because we're going to user same
     * type for both and we don't want to make some mistakes :) *)
    let is_email_in_egroup ~email ~egroupid =
      full_transaction_block
        (fun dbh ->
           Q.is_email_in_egroup dbh ~email ~egroupid)

    (* CHARLY: same here *)
    let add_email_in_egroup ~email ~egroupid =
      full_transaction_block
        (fun dbh ->
           lwt b = Q.is_email_in_egroup dbh ~email ~egroupid in
           (* true -> in the group, false -> not in the group *)
           if b
           (* we don't need to add user to the groups because he already belongs to it *)
           then Lwt.return ()
           (* here, ew add the user to a group *)
           else
             Lwt_Query.query dbh
               <:insert< $email_egroups_table$ := { email = $string:email$;
                                                    groupid = $int64:egroupid$ }
               >>)

    (* CHARLY: same here *)
    let remove_email_in_egroup ~email ~egroupid =
      full_transaction_block
        (fun dbh ->
           Lwt_Query.query dbh
             <:delete< ug in $email_egroups_table$
                       | ug.email = $string:email$;
                         ug.groupid = $int64:egroupid$;
             >>)

    let does_egroup_exist name =
      full_transaction_block
        (fun dbh ->
           Q.does_egroup_exist dbh name)

    let get_emails_in_egroup ~egroupid ~n =
      full_transaction_block
        (fun dbh ->
           let n = Int64.of_int n in
           let n_limit = <:value< $int64:n$ >> in
           lwt l =
             Lwt_Query.view dbh
               <:view< e limit $n_limit$ | e in $email_egroups_table$;
                                   e.groupid = $int64:egroupid$ >>
           in
           Lwt.return (List.map (fun e -> e#!email) l))

    let all_egroups () =
      full_transaction_block
        (fun dbh ->
           Lwt_Query.query dbh
             <:select< g | g in $egroups_table$ >>)
  end

  module Eg = Egroups

end
