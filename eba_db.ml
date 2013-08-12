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
  method port : int
  method name : string
  method workers : int
end

module type T = sig
  module U : sig
    type t =
      < firstname : < get : unit; nul : Sql.non_nullable; t : Sql.string_t > Sql.t;
        lastname : < get : unit; nul : Sql.non_nullable; t : Sql.string_t > Sql.t;
        pic : < get : unit; nul : Sql.nullable; t : Sql.string_t > Sql.t;
        pwd : < get : unit; nul : Sql.nullable; t : Sql.string_t > Sql.t;
        userid : < get : unit; nul : Sql.non_nullable; t : Sql.int64_t > Sql.t
      >


    module Q : sig
      val is_registered : 'a Lwt_Query.Db.t -> string -> bool Lwt.t
      val is_preregistered : 'a Lwt_Query.Db.t -> string -> bool Lwt.t
      val create_activation_key : 'a Lwt_Query.Db.t -> string -> string -> unit Lwt.t
      val create_user : 'a Lwt_Query.Db.t -> ?avatar:string -> string -> string -> int64 Lwt.t
      val does_user_exist : 'a Lwt_Query.Db.t -> string -> int64 option Lwt.t
    end
    val is_registered : string -> bool Lwt.t
    val is_preregistered : string -> bool Lwt.t
    val is_registered_or_preregistered : string -> bool Lwt.t
    val all_preregistered : unit -> string list Lwt.t
    val check_pwd : string -> string -> int64 Lwt.t
    val does_user_exist : string -> bool Lwt.t

    val new_activation_key : string -> string -> unit Lwt.t
    val new_preregister_email : string -> unit Lwt.t
    val new_user_from_mail : ?avatar:string -> string -> string -> int64 Lwt.t

    val set_password : int64 -> string -> unit Lwt.t
    val set_pic : int64 -> string -> unit Lwt.t
    val set_personal_data : int64 -> string -> string -> string -> unit Lwt.t

    val get_users_from_name : (string * string) -> t list Lwt.t
    val get_userid_from_activationkey : string -> int64 Lwt.t
    val get_userslist : unit -> t list Lwt.t
    val get_pic : int64 -> string option Lwt.t
  end

  module G : sig
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

  (********* Queries *********)
  module G = struct

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
           lwt () =
             match description with
               | None ->
                   Lwt_Query.query dbh
                     <:insert<
                     $groups_table$ := { groupid = groups_table?groupid;
                                         name = $string:name$;
                                         description = $Sql.Op.null$ }
                     >>
               | Some d ->
                   Lwt_Query.query dbh
                     <:insert<
                     $groups_table$ := { groupid = groups_table?groupid;
                                         name = $string:name$;
                                         description = $string:d$ }
                     >>
           in Lwt.return ())

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

  module U = struct

    type t =
      < firstname : < get : unit; nul : Sql.non_nullable; t : Sql.string_t > Sql.t;
        lastname : < get : unit; nul : Sql.non_nullable; t : Sql.string_t > Sql.t;
        userid : < get : unit; nul : Sql.non_nullable; t : Sql.int64_t > Sql.t;
        pwd : < get : unit; nul : Sql.nullable; t : Sql.string_t > Sql.t;
        pic : < get : unit; nul : Sql.nullable; t : Sql.string_t > Sql.t;
      >

    module Q = struct
      let is_registered dbh m =
        try_lwt
          lwt _ = Lwt_Query.view_one dbh
          <:view< e | e in $emails_table$;
                      e.email = $string:m$ >>;
          in
          Lwt.return true
        with _ -> Lwt.return false

      let is_preregistered dbh m =
        try_lwt
          lwt _ = Lwt_Query.view_one dbh
          <:view< p | p in $preregister_table$;
                      p.email = $string:m$ >>;
          in
          Lwt.return true
        with _ -> Lwt.return false

      let create_activation_key dbh email key =
        Lwt_Query.query dbh
        <:insert< $activation_table$ :=
          {activationkey = $string:key$;
           email = $string:email$;
           creationdate = activation_table?creationdate } >>

      let create_user dbh ?avatar email key =
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
        lwt () = create_activation_key dbh email key in
        Lwt.return userid

      let does_user_exist dbh email =
        try_lwt
          lwt e = Lwt_Query.view_one dbh
            <:view< e | e in $emails_table$;
                        e.email = $string:email$ >>
          in
          Lwt.return (Some e#!userid)
        with _ -> Lwt.return None
    end

    let new_preregister_email m =
      full_transaction_block
        (fun dbh ->
           Lwt_Query.query dbh
             <:insert<
                $preregister_table$ := { email = $string:m$; }
             >>)

    let is_registered m =
      full_transaction_block
        (fun dbh ->
           (* this will return a Lwt.t *)
           Q.is_registered dbh m)

    let is_preregistered m =
      full_transaction_block
        (fun dbh ->
           (* this will return a Lwt.t *)
           Q.is_preregistered dbh m)

    let is_registered_or_preregistered m =
      full_transaction_block
        (fun dbh ->
           lwt b1 = Q.is_preregistered dbh m in
           lwt b2 = Q.is_registered dbh m in
           Lwt.return (b1 || b2))

    let all_preregistered () =
      full_transaction_block
        (fun dbh ->
           lwt l = (Lwt_Query.query dbh
                      <:select< p | p in $preregister_table$; >>)
           in
           Lwt.return (List.map (fun r -> r#!email) l))



    let password_view =
      <:view< {email = e.email; pwd = u.pwd; userid=u.userid} |
          u in $users_table$;
          e in $emails_table$;
          u.userid = e.userid >>

    module MCache_in = struct
      type key_t = int64
      type value_t = Eba_common0.user

      let compare = compare
      let get key =
        full_transaction_block
          (fun dbh ->
             try_lwt
               lwt u =
                 Lwt_Query.view_one dbh
                   <:view< r | r in $users_table$;
                               r.userid = $int64:key$
                   >>
               in
               let user = Eba_common0.create_user_from_db_info u in
               Lwt.return user
             with
               | _ -> Lwt.fail Eba_common0.No_such_user)
    end
    module MCache = Eba_cache.Make(MCache_in)

    let get_user (uid : int64) =
      (MCache.get uid :> Eba_common0.user Lwt.t)

    let reset_user (uid : int64) : unit =
      MCache.reset uid

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



    let does_user_exist m =
      full_transaction_block
        (fun dbh ->
          match_lwt Q.does_user_exist dbh m with
            | Some _ -> Lwt.return true
            | None -> Lwt.return false)

    (** If the email does not exist, create it, add the activation id,
        and create the user.
        if it exists, set the new activation key. *)
    let new_activation_key email key =
      full_transaction_block
        (fun dbh ->
          match_lwt Q.does_user_exist dbh email with
            | Some _ -> Q.create_activation_key dbh email key
            | None -> lwt _ = Q.create_user dbh email key in Lwt.return ()
        )


    let new_user_from_mail ?avatar email key =
      full_transaction_block
        (fun dbh ->
          match_lwt Q.does_user_exist dbh email with
            | None -> Q.create_user dbh ?avatar email key
            | Some userid -> Lwt.return userid)


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


    let set_password userid pwd =
      full_transaction_block (fun dbh ->
        lwt () = Lwt_Query.query dbh
          <:update< u in $users_table$ := { pwd = $string:pwd$;
                                          } |
                    u.userid = $int64:userid$ >>
        in
        reset_user userid;
        Lwt.return ()
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
      Lwt.return u.Eba_common0.useravatar

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

  end
end
