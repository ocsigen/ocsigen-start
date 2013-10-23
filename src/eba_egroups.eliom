exception No_such_egroup

module type T = sig
  type t = Eba_types.Egroups.t

  val create : ?description:string -> string -> t Lwt.t
  val get : string -> t option Lwt.t
  val all : unit -> t list Lwt.t

  val add_email : email:string -> egroup:t -> unit Lwt.t
  val remove_email : email:string -> egroup:t -> unit Lwt.t
  val in_egroup : email:string -> egroup:t -> bool Lwt.t

  val get_emails_in : egroup:t -> n:int -> string list Lwt.t

  val id_of_egroup : t -> int64
  val name_of_egroup : t -> string
  val desc_of_egroup : t -> string option

  val preregister : t
end

module Make(M : sig
  module Database : Eba_db.T
end)
=
struct
  include Eba_shared.Egroups

  let create_egroup_with (g : M.Database.Eg.t) =
    let open Eba_types.Egroups in
    {
      id   = (Sql.get g#groupid);
      name = (Sql.get g#name);
      desc = (Sql.getn g#description);
    }

  module MCache_in = struct
    type key_t = string
    type value_t = Eba_types.Egroups.t

    let compare = compare
    let get key =
      match_lwt M.Database.Eg.does_egroup_exist key with
        | Some g -> Lwt.return (create_egroup_with g)
        | None -> Lwt.fail No_such_egroup
  end
  module MCache = Cache.Make(MCache_in)

  (** creates the egroup in the database if it does
    * not exist, or returns its id as an abstract value *)
  let create ?description name =
    match_lwt M.Database.Eg.does_egroup_exist name with
     | Some g -> Lwt.return (create_egroup_with g)
     | None ->
         (* we can't use the cache here, because we can use create at top-level
          * and we don't have access to request scope at top-level *)
         lwt () = M.Database.Eg.new_egroup ?description name in
         lwt g = M.Database.Eg.get_egroup name in
         Lwt.return (create_egroup_with g)

  let get name =
    try_lwt
      lwt g = MCache.get name in
      Lwt.return (Some g)
    with
      | No_such_egroup -> Lwt.return None

  let add_email ~email ~egroup =
    M.Database.Eg.add_email_in_egroup
      ~email
      ~egroupid:(id_of_egroup egroup)

  let remove_email ~email ~egroup =
    M.Database.Eg.remove_email_in_egroup
      ~email
      ~egroupid:(id_of_egroup egroup)

  let in_egroup ~email ~egroup =
    M.Database.Eg.is_email_in_egroup
      ~email
      ~egroupid:(id_of_egroup egroup)

  let get_emails_in ~egroup ~n =
    M.Database.Eg.get_emails_in_egroup
      ~egroupid:(id_of_egroup egroup)
      ~n

  let all () =
    lwt l = M.Database.Eg.all_egroups () in
    let put_in_cache g =
      let g = create_egroup_with g in
      let () = MCache.set (name_of_egroup g) g in
      g
    in
    Lwt.return
      (List.map
         (put_in_cache)
         (l))

  let preregister = Lwt_unix.run (create "preregister")
end
