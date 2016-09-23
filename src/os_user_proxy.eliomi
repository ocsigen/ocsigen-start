(* WARNING generated in an ad-hoc fashion. Use with care! *)
[%%shared.start]
type userid = int64 [@@deriving json]

[%%server.start]

val cache : (userid, Os_user.t) Eliom_cscache.t

val get_data_from_db : 'a -> Os_user.id -> Os_user.t Lwt.t

val get_data : Os_user.id -> Os_user.t Lwt.t

val get_data_from_db_for_client : 'a -> Os_user.id -> Os_user.t Lwt.t

val get_data_rpc' : Os_user.id -> Os_user.t Lwt.t

[%%client.start]

val get_data_rpc' : unit

val get_data : Os_user.id -> Os_user.t Lwt.t

[%%shared.start]

val get_data_rpc : (userid, Os_user.t) Eliom_client.server_function

val get_data_from_cache : userid -> Os_user.t Lwt.t
