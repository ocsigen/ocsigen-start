exception No_such_group

module type T = sig
  type t = Eba_types.Groups.t

  val create : ?description:string -> string -> t Lwt.t
  val get : string -> t Lwt.t

  val all : unit -> t list Lwt.t

  val add_user : userid:int64 -> group:t -> unit Lwt.t
  val remove_user : userid:int64 -> group:t -> unit Lwt.t
  val in_group : userid:int64 -> group:t -> bool Lwt.t

  val id_of_group : t -> int64
  val name_of_group : t -> string
  val desc_of_group : t -> string option

  val admin : t
end

module Make(M : Eba_database.Tgroups) = struct
  include Eba_shared.Groups

  module MCache = Eba_tools.Cache_f.Make(
  struct
    type key_t = string
    type value_t = Eba_types.Groups.t

    let compare = compare
    let get key =
      match_lwt M.get_group key with
        | Some g -> Lwt.return g
        | None -> Lwt.fail No_such_group
  end)

  (** creates the group in the database if it does
    * not exist, or returns its id as an abstract value *)
  let create ?description name =
    match_lwt M.get_group name with
     | Some g -> Lwt.return g
     | None ->
         (* we can't use the cache here, because we can use create at top-level
          * and we don't have access to request scope at top-level *)
         lwt () = M.new_group ?description name in
         match_lwt M.get_group name with
           | None -> raise No_such_group
           | Some g -> Lwt.return g

  let get name =
    MCache.get name

  let add_user ~userid ~group =
    M.add_user_in_group
      ~userid ~group

  let remove_user ~userid ~group =
    M.remove_user_in_group
      ~userid ~group

  let in_group ~userid ~group =
    M.in_group
      ~userid ~group

  let all () =
    M.all ()

  let admin =
    Lwt_unix.run (create "admin")
end
