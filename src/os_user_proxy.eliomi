(* WARNING generated in an ad-hoc fashion. Use with care! *)
[%%server.start]
type userid = int64

val userid_of_json : Deriving_Json_lexer.lexbuf -> userid

val userid_to_json : Buffer.t -> userid -> unit

val userid_json : userid Deriving_Json.t

val cache : (userid, Os_user.t) Eliom_cscache.t

val get_data_from_db : 'a -> Os_user.id -> Os_user.t Lwt.t

val get_data : Os_user.id -> Os_user.t Lwt.t

val get_data_from_db_for_client : 'a -> Os_user.id -> Os_user.t Lwt.t

val get_data_rpc' : Os_user.id -> Os_user.t Lwt.t

val get_data_rpc : (userid, Os_user.t) Eliom_client.server_function

val get_data_from_cache : userid -> Os_user.t Lwt.t
