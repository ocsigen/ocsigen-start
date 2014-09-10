(* Feel free to modify and/or redistribute this file as you wish. *)


(* current user *)
let me : Eba_user.t option Eliom_reference.Volatile.eref =
  (* This is a request cache of current user *)
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope None


{client{

let me : Eba_user.t option ref = ref None

let get_current_user_option () = !me

let get_current_user () =
  match !me with
  | Some a -> a
  | None ->
    Ow_log.log "Not connected error in Eba_current_user";
    raise Eba_session.Not_connected

}}


(* SECURITY: We can trust these functions on server side,
   because the user is set at every request from the session cookie value.
   But do not trust a user sent by te client ...
*)
let get_current_user () =
  match Eliom_reference.Volatile.get me with
  | Some a -> a
  | None -> raise Eba_session.Not_connected

let get_current_user_option () =
  Eliom_reference.Volatile.get me

{shared{
module Opt = struct

  let get_current_user = get_current_user_option

  let get_current_userid () =
    Eliom_lib.Option.map
      Eba_user.uid_of_user
      (get_current_user_option ())

end
 }}

let set_user_server uid =
  lwt u = Eba_user.user_of_uid uid in
  Eliom_reference.Volatile.set me (Some u);
  Lwt.return ()

let unset_user_server () =
  Eliom_reference.Volatile.set me None

let set_user_client () =
  let u = Eliom_reference.Volatile.get me in
  ignore {unit{ me := %u }}

let unset_user_client () =
  ignore {unit{ me := None }}




let last_activity : CalendarLib.Calendar.t option Eliom_reference.eref =
  Eliom_reference.eref
    ~persistent:"lastactivity"
    ~scope:Eliom_common.default_group_scope
    None

let () =
  Eba_session.on_start_connected_process (fun userid ->
    lwt () = set_user_server userid in
    set_user_client ();
    Lwt.return ());
  Eba_session.on_connected_request (fun userid ->
    lwt () = set_user_server userid in
    let now = Eba_date.gmtnow () in
    Eliom_reference.set last_activity (Some now));
  Eba_session.on_close_session (fun () ->
    unset_user_client (); (*VVV!!! will affect only current tab!! *)
    unset_user_server (); (* ok this is a request reference *)
    Lwt.return ())
