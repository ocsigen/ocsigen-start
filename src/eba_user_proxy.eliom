(* Copyright Vincent Balat *)

(*VVV Warning: Eba already implements a cache of user, but for
  Eba_user.t only. It's ok. *)

[%%shared
    type userid = int64 [@@deriving json]
]

let%server cache : (userid, Eba_user.t) Eliom_cscache.t =
  Eliom_cscache.create ()


[%%server

   let get_data_from_db myid_o userid =
     Eba_user.user_of_userid userid

  let get_data userid =
     let myid_o = Eba_current_user.Opt.get_current_userid () in
     get_data_from_db myid_o userid

  let get_data_from_db_for_client myid_o userid =
    get_data_from_db myid_o userid

]

let%server get_data_rpc' =
  Eba_session.Opt.connected_rpc get_data_from_db_for_client
let%client get_data_rpc' = ()

let%shared get_data_rpc
  : (_, Eba_user.t) Eliom_client.server_function =
  Eliom_client.server_function ~name:"eba_user_proxy.get_data_rpc"
    [%derive.json: userid] get_data_rpc'

let%client get_data id  = get_data_rpc id

[%%shared
   let get_data_from_cache userid =
     Eliom_cscache.find ~%cache get_data userid
]
