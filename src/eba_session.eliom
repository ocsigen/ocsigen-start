(* Copyright Vincent Balat, Charly Chevalier *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

class type config = object
  method on_open_session : unit Lwt.t
  method on_close_session : unit Lwt.t
  method on_start_process : unit Lwt.t
  method on_start_connected_process : unit Lwt.t
end

{client{

  (* This will close the client process *)
  let close_client_process () =
    let d =
      D.div ~a:[a_class ["eba_process_closed"]] [
        img ~alt:("Ocsigen Logo")
          ~src:(Xml.uri_of_string ("http://ocsigen.org/resources/logos/ocsigen_with_shadow.png"))
          ();
        p [
          pcdata "Ocsigen process closed.";
          br ();
          a ~xhr:false
            ~service:Eliom_service.void_coservice'
            [pcdata "Click"]
            ();
          pcdata " to restart."
        ];
      ]
    in
    let d = To_dom.of_div d in
    Dom.appendChild (Dom_html.document##body) d;
    lwt () = Lwt_js_events.request_animation_frame () in
    d##style##backgroundColor <- Js.string "rgba(255, 255, 255, 0.7)";
    Lwt.return ()
}}

module type T = sig
  val connect_wrapper_function :
     ?allow:Eba_types.Groups.t list
  -> ?deny:Eba_types.Groups.t list
  -> (int64 -> 'a -> 'b -> 'c Lwt.t)
  -> 'a -> 'b
  -> 'c Lwt.t

  val anonymous_wrapper_function :
     ?allow:Eba_types.Groups.t list
  -> ?deny:Eba_types.Groups.t list
  -> (int64 option -> 'a -> 'b -> 'c Lwt.t)
  -> 'a -> 'b
  -> 'c Lwt.t

  val connect_wrapper_rpc :
     ?allow:Eba_types.Groups.t list
  -> ?deny:Eba_types.Groups.t list
  -> (int64 -> 'a -> 'b Lwt.t)
  -> 'a
  -> 'b Lwt.t

  val anonymous_wrapper_rpc :
     ?allow:Eba_types.Groups.t list
  -> ?deny:Eba_types.Groups.t list
  -> (int64 option -> 'a -> 'b Lwt.t)
  -> 'a
  -> 'b Lwt.t

  val connect : int64 -> unit Lwt.t
  val logout : unit -> unit Lwt.t
end

module Make(M : sig
  val config : config

  module Groups : Eba_groups.T
  module User : Eba_user.T
  module Database : Eba_db.T
end)
=
struct

  exception Permission_denied

  let me : Eba_types.User.t option Eliom_reference.Volatile.eref =
    (* This is a cache of current user *)
    Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope None

  (* SECURITY: We can trust these functions on server side,
     because the user is set at every request from the session cookie value.
     But do not trust a user sent by te client ...
  *)
  let get_current_user_or_fail () =
    match Eliom_reference.Volatile.get me with
      | Some a -> a
      | None -> raise Eba_shared.Session.Not_connected

  let get_current_user_option () =
    Eliom_reference.Volatile.get me

  (*VVV!!! I am not happy with these 2 functions set_user.
    If we forget to call them, the user will be wrong.
    get_current_user_or_fail could call User.user_of_uid itself
    but it does not work if we want to set the client side value ...
    For the client side value, we could use a wrapped reference but
    - the value must be set before wrapping, otherwise we will wrap a lwt
    thread ... We need a wrapper that waits the end of the server side threads
    and wrap the value it returns?
    - if they are sent only once, the value will be wrong because when
    the client side program starts, the value is None
    - if they are sent every request, it's too much, and this is probably
    not the right semantics for wrapping Eliom references

  *)
  let set_user_server uid =
    lwt u = M.User.user_of_uid uid in
    Eliom_reference.Volatile.set me (Some u);
    Lwt.return ()

  let unset_user_server () =
    Eliom_reference.Volatile.set me None

  let set_user_client () =
    let u = Eliom_reference.Volatile.get me in
    ignore {unit{ Eba_shared.Session.me := %u }}

  let unset_user_client () =
    ignore {unit{ Eba_shared.Session.me := None }}

  let start_connected_process () =
    let () = set_user_client () in
    (* We want to warn the client when the server side process state is closed.
       To do that, we listen on a channel and wait for exception. *)
    let c : unit Eliom_comet.Channel.t =
      Eliom_comet.Channel.create (fst (Lwt_stream.create ())) in
    let _ =
      {unit{
        Lwt.async (fun () ->
          Lwt.catch (fun () ->
            Lwt_stream.iter_s
              (fun () -> Lwt.return ())
              %c)
            (function
              | Eliom_comet.Process_closed ->
                close_client_process ()
              | e ->
                Eliom_lib.debug_exn "comet exception: " e;
                Lwt.fail e))
      }}
    in
    M.config#on_start_connected_process

  let connect_volatile userid =
    Eliom_state.set_volatile_data_session_group
      ~scope:Eliom_common.default_session_scope userid;
    M.config#on_open_session

  let connect_string userid =
    lwt () = Eliom_state.set_persistent_data_session_group
      ~scope:Eliom_common.default_session_scope userid in
    lwt () = connect_volatile userid in
    start_connected_process ()

  let connect userid =
    try_lwt
      lwt () = set_user_server userid in
      connect_string (Int64.to_string userid)
    with Eba_user.No_such_user -> M.config#on_close_session

  let check_allow_deny userid allow deny =
    lwt b = match allow with
      | None -> Lwt.return true (* By default allow all *)
      | Some l -> (* allow only users from one of the groups of list l *)
        Lwt_list.fold_left_s
          (fun b group ->
            lwt b2 = M.Groups.in_group ~userid ~group in
            Lwt.return (b || b2)) false l
    in
    lwt b = match deny with
      | None -> Lwt.return b (* By default deny nobody *)
      | Some l -> (* allow only users that are not
                     in one of the groups of list l *)
        Lwt_list.fold_left_s
          (fun b group ->
            lwt b2 = M.Groups.in_group ~userid ~group in
            Lwt.return (b && (not b2))) b l
    in
    if b then Lwt.return () else Lwt.fail Permission_denied


  (** The connection wrapper checks whether the user is connected,
      and if not displays the login page.

      If yes, [gen_wrapper connected on_start_process non_connected gp pp]
      calls the [connected] function given as parameters,
      taking user name, GET parameters [gp] and POST parameters [pp].

      If not, it calls the [not_connected] function.

      If we are launching a new client side process,
      functions [on_start_process] is called,
      and also [on_start_connected_process] if connected.
  *)
  let gen_wrapper ~allow ~deny connected not_connected gp pp =
    try_lwt
      let new_process = Eliom_request_info.get_sp_client_appl_name () = None in
      let uids = Eliom_state.get_volatile_data_session_group () in
      let get_uid uid = try
                          (match uid with
                            | None -> None
                            | Some u -> Some (Int64.of_string u))
        with Failure _ -> None
      in
      lwt uid = match get_uid uids with
        | None ->
          lwt uids = Eliom_state.get_persistent_data_session_group () in
          (match get_uid uids  with
            | Some uid ->
              (* A persistent session exists, but the volatile session has gone.
                 It may be due to a timeout or may be the server has been
                 relaunched.
                 We restart the volatile session silently
                 (comme si de rien n'était, pom pom pom). *)
              lwt () = set_user_server uid in
              (* We record the user info on server side
                 as a request reference.
                 As it is computed from the session cookie,
                 it is safe on server side. *)
              lwt () = connect_volatile (Int64.to_string uid) in
              Lwt.return (Some uid)
            | None -> Lwt.return None)
        | Some uid ->
          lwt () = set_user_server uid in
          Lwt.return (Some uid)
      in
      lwt () = if new_process
        then begin
          (* client side process:
             Now we want to do some computation only when we start a
             client side process. *)
          lwt () = M.config#on_start_process in
          match uid with
            | None -> Lwt.return ()
            | Some id -> (* new client process, but already connected *)
              start_connected_process ()
        end
        else Lwt.return ()
      in
      match uid with
        | None ->
          if allow = None
          then not_connected gp pp
          else Lwt.fail Permission_denied
        | Some id ->
          lwt () = check_allow_deny id allow deny in
          connected id gp pp
    with Eba_user.No_such_user ->
      lwt () = M.config#on_close_session in
      not_connected gp pp

  (* connect_wrapper_action checks user connection
     and fails if not connected. *)
  let connect_wrapper_function ?allow ?deny f gp pp =
    gen_wrapper
      ~allow ~deny
      f
      (fun _ _ -> Lwt.fail Eba_shared.Session.Not_connected)
      gp pp

  let anonymous_wrapper_function ?allow ?deny f gp pp =
    gen_wrapper
      ~allow ~deny
      (fun userid gp pp -> f (Some userid) gp pp)
      (fun gp pp -> f None gp pp)
      gp pp

  let connect_wrapper_rpc ?allow ?deny f pp =
    gen_wrapper
      ~allow ~deny
      (fun userid _ p -> f userid p)
      (fun _ _ -> Lwt.fail Eba_shared.Session.Not_connected)
      () pp

  let anonymous_wrapper_rpc ?allow ?deny f pp =
    gen_wrapper
      ~allow ~deny
      (fun userid _ p -> f (Some userid) p)
      (fun _ p -> f None p)
      () pp

  let logout () =
    unset_user_client (); (*VVV!!! will affect only current tab!! *)
    unset_user_server (); (* ok this is a request reference *)
    M.config#on_close_session

end
