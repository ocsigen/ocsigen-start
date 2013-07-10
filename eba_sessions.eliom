(* Copyright Vincent Balat *)

{shared{
open Eliom_content.Html5
open Eliom_content.Html5.F
exception Not_connected
}}

exception Permission_denied

(********* Eliom references *********)
let wrong_password =
  Eliom_reference.eref ~scope:Eliom_common.request_scope false

let wrong_perso_data
 : ((string * string) * (string * string)) option Eliom_reference.Volatile.eref
    =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope None

let activationkey_created =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let me : Eba_common0.user option Eliom_reference.Volatile.eref =
  (* This is a cache of current user *)
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope None

(* SECURITY: We can trust these functions on server side,
   because the user is set at every request from the session cookie value.
   But do not trust a user sent by te client ...
*)
let get_current_user_or_fail () =
  match Eliom_reference.Volatile.get me with
    | Some a -> a
    | None -> raise Not_connected
let get_current_user_option () = Eliom_reference.Volatile.get me



(*VVV!!! I am not happy with these 2 functions set_user.
  If we forget to call them, the user will be wrong.
  get_current_user_or_fail could call Eba_db.get_user itself
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
  lwt u = Eba_db.get_user uid in
  Eliom_reference.Volatile.set me (Some u);
  Lwt.return ()

let unset_user_server () =
  Eliom_reference.Volatile.set me None


{client{
let me = ref None
}}

let set_user_client () =
  let u = Eliom_reference.Volatile.get me in
  ignore {unit{ me := %u }}

let unset_user_client () =
  ignore {unit{ me := None }}

{client{

let get_current_user_or_fail () =
  match !me with
    | Some a -> a
    | None -> Eba_misc.alert "Not connected error in Eba_sessions";
      raise Not_connected


(* This will close the client process *)
let close_client_process () =
  let d = D.div ~a:[a_class ["ol_process_closed"]]
    [img ~alt:("Ocsigen Logo")
        ~src:(Xml.uri_of_string ("https://ocsigen.org/resources/logos/ocsigen_with_shadow.png"))
        ();
     p [pcdata "Ocsigen process closed.";
        br ();
        a ~xhr:false
          ~service:Eliom_service.void_coservice'
          [pcdata "Click"] ();
        pcdata " to restart."];
    ]
  in
  let d = To_dom.of_div d in
  Dom.appendChild (Dom_html.document##body) d;
  lwt () = Lwt_js_events.request_animation_frame () in
  d##style##backgroundColor <- Js.string "rgba(255, 255, 255, 0.7)";
  Lwt.return ()

}}

(*****************************************************************************)
(* Connection wrappers *)

module Connect_Wrappers(A : sig
  val open_session : unit -> unit Lwt.t
                   (** Function to be called when opening a new session. *)
  val close_session : unit -> unit Lwt.t
                   (** Function to be called when closing a session. *)
  val start_process : unit -> unit Lwt.t
                   (** The function to be called every time we launch a new
                       client side process (e.g. opening a new tab) *)
  val start_connected_process : unit -> unit Lwt.t
                   (** The function to be called every time we launch a new
                       client side process (e.g. opening a new tab) when
                       user is connected, or when a user logs in. *)
end) = struct


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
    A.start_connected_process ()

  let connect_volatile userid =
    Eliom_state.set_volatile_data_session_group
      ~scope:Eliom_common.default_session_scope userid;
    A.open_session ()

  let connect_string userid =
    lwt () = Eliom_state.set_persistent_data_session_group
      ~scope:Eliom_common.default_session_scope userid in
    lwt () = connect_volatile userid in
    start_connected_process ()

  let connect userid =
    try_lwt
      lwt () = set_user_server userid in
      connect_string (Int64.to_string userid)
    with Eba_common0.No_such_user -> A.close_session ()

  (** The connection wrapper checks whether the user is connected,
      and if not displays the login page.

      If yes, [gen_wrapper connected start_process non_connected gp pp]
      calls the [connected] function given as parameters,
      taking user name, GET parameters [gp] and POST parameters [pp].

      If not, it calls the [not_connected] function.

      If we are launching a new client side process,
      functions [start_process] is called,
      and also [start_connected_process] if connected.
  *)
  let gen_wrapper connected not_connected gp pp =
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
          lwt () = A.start_process () in
          match uid with
            | None -> Lwt.return ()
            | Some id -> (* new client process, but already connected *)
              start_connected_process ()
        end
        else Lwt.return ()
      in
      match uid with
        | None -> not_connected gp pp
        | Some id -> connected id gp pp
    with Eba_common0.No_such_user ->
      lwt () = A.close_session () in
      not_connected gp pp

  (* connect_wrapper_action checks user connection
     and fails if not connected. *)
  let connect_wrapper_function f gp pp =
    gen_wrapper f (fun _ _ -> Lwt.fail Not_connected) gp pp

  let connect_wrapper_rpc f pp =
    gen_wrapper
      (fun userid _ p -> f userid p)
      (fun _ _ -> Lwt.fail Not_connected)
      () pp

  let anonymous_wrapper_rpc f pp =
    gen_wrapper
      (fun userid _ p -> f (Some userid) p)
      (fun _ p -> f None p)
      () pp

  let logout () =
    unset_user_client (); (*VVV!!! will affect only current tab!! *)
    unset_user_server (); (* ok this is a request reference *)
    A.close_session ()

end
