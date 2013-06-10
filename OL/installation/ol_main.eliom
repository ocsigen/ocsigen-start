(* Copyright Vincent Balat, Séverine Maingaud *)

(** Main module. Web interaction.
    Definition of service handlers and registration of services. *)

{shared{
open Eliom_content.Html5
open Eliom_content.Html5.F
}}
open Ol_services

module Ol_fm = Ol_flash_message

module Make(A : sig
  val app_name : string (** short app name to be used as file name *)
  val capitalized_app_name : string
                        (** Full application name to be displayed on pages *)
  val css_list : string list list (** css to be added to each page *)
  val js_list : string list list (** js to be added to each page *)
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
                       user is connected, or we a user logs in. *)
end) = struct

  module CW = Ol_sessions.Connect_Wrappers(A)

  include CW

  let main_title = Ol_site_widgets.main_title A.capitalized_app_name

  module My_appl =
    Eliom_registration.App (
      struct
        let application_name = A.app_name
      end)


  (********* Service handlers *********)
  let page_container content =
    let css = List.map (fun cssname -> ("css"::cssname))
      (["eliom_ui.css"]::["ol.css"]::A.css_list)
    in
    let js = List.map (fun jsname -> ("js"::jsname)) (["jquery.js"]::A.js_list)
    in
    (html
       (Eliom_tools.F.head ~title:A.capitalized_app_name ~css ~js ())
       (body content))

  let error_page msg =
    Lwt.return (page_container
                  [main_title;
                   Ol_site_widgets.mainpart
                     ~class_:["ol_error"] [p [pcdata msg]]])

  let logout_action () () =
    (* SECURITY: no check here because we logout the session cookie owner. *)
    lwt () = CW.logout () in
    lwt () = Eliom_state.discard ~scope:Eliom_common.default_session_scope () in
    lwt () = Eliom_state.discard ~scope:Eliom_common.default_process_scope () in
    Eliom_state.discard ~scope:Eliom_common.request_scope ()

  let login_action () (login, pwd) =
    (* SECURITY: no check here. *)
    lwt () = logout_action () () in
    try_lwt
      lwt userid = Ol_db.check_pwd login pwd in
      CW.connect userid
    with Not_found -> Ol_fm.set_flash_msg Ol_fm.Wrong_password

  let login_page ?(invalid_actkey = false) _ _ =
    lwt state = Ol_site.get_state () in
    let cb = Ol_base_widgets.login_signin_box ~invalid_actkey ~state
               login_service
               lost_password_service
               sign_up_service
               preregister_service
    in
    Lwt.return
      (page_container
         [div
             ~a:[a_class ["ol_welcomepage"]]
             [main_title; cb]])

let send_activation_email ~email ~uri () =
  try_lwt
    ignore (Netaddress.parse email);
    Ol_misc.send_mail
      ~from_addr:("Myproject Team", "noreply@ocsigenlabs.com")
      ~to_addrs:[("", email)]
      ~subject:"Myproject registration"
      ("To activate your Myproject account, please visit the \
             following link:\n" ^ uri
       ^ "\n"
       ^ "This is an auto-generated message. "
       ^ "Please do not reply.\n")
  with _ -> (Eliom_lib.debug "SENDING INVITATION FAILED" ; Lwt.return false)

  (** will generate an activation key which can be used to login
      directly. This key will be send to the [email] address *)
  let generate_new_key email =
    let activationkey = Ocsigen_lib.make_cryptographic_safe_string () in
    lwt () = Ol_db.new_activation_key email activationkey in
    let uri = Eliom_content.Html5.F.make_string_uri
                ~absolute:true
                ~service:Ol_services.activation_service
                activationkey
    in
    (*VVV REMOOOOOOOOOOOOOOOOOOOVE! *)
    Ol_misc.log ("REMOVE ME activation link: "^uri);
    lwt _ = send_activation_email ~email ~uri () in
    Eliom_reference.Volatile.set Ol_sessions.activationkey_created true;
    Lwt.return ()

  let sign_up_action () email =
    match_lwt Ol_db.user_exists email with
      | false -> generate_new_key email
      | true -> Ol_fm.set_flash_msg (Ol_fm.User_already_exists email)


  let lost_password_action () email =
    (* SECURITY: no check here. *)
    match_lwt Ol_db.user_exists email with
      | false -> Ol_fm.set_flash_msg (Ol_fm.User_does_not_exist email)
      | true -> generate_new_key email


  let connect_wrapper_page f gp pp =
    CW.gen_wrapper f login_page gp pp

  let new_user user = user.Ol_common0.new_user


  let activation_handler activationkey () =
    (* SECURITY: no check here. We logout before doing anything. *)
    lwt () = logout_action () () in
    try_lwt
      (* If the activationkey is valid, we connect the user *)
      lwt userid = Ol_db.get_userid_from_activationkey activationkey in
      lwt () = CW.connect userid in
      (* Then reload the page without the activation parameter *)
      Eliom_registration.Redirection.send Eliom_service.void_coservice'
    with Not_found -> (* outdated activation key *)
      lwt page = login_page ~invalid_actkey:true () () in
      My_appl.send page

  let set_personal_data_action userid ()
      (((firstname, lastname), (pwd, pwd2)) as v) =
    (* SECURITY: We get the userid from session cookie,
       and change personal data for this user. No other check. *)
    if firstname = "" || lastname = "" || pwd <> pwd2
    then (Eliom_reference.Volatile.set Ol_sessions.wrong_perso_data (Some v);
          Lwt.return ())
    else let pwd = Bcrypt.hash pwd in
         Ol_db.set_personal_data userid firstname lastname (Bcrypt.string_of_hash pwd)


  (* make a request to the DB to get the list of all users,
     then make a first filter to get the list of possible
     completions of post_parameter *)
  let get_userlist_for_completion_handler _uid g p =
(*VVV!!! SECURITY: do we want to search in all users? *)
    lwt userlist = Ol_db.get_userslist () in
    let userlist = List.map Ol_common0.create_user_from_db_info userlist in
    let f u =
      let s =  Ew_accents.without (Ol_common0.name_of_user u) in
      Ew_completion.is_completed_by (Ew_accents.without p) s
    in
    Lwt.return (List.filter f userlist)

  let avatar_dir =
    let r = ref "" in
    Eliom_config.parse_config
      Ocsigen_extensions.Configuration.([
        element ~name:"avatars" ~obligatory:true
          ~attributes:[
            attribute ~name:"dir" ~obligatory:true (fun v -> r := v);
          ]
          ()
      ]);
    if !r = "" then failwith "Please set option <avatars dir=\"...\" /> for this Eliom module";
    r

  let set_pic userid () pic =
(*VVV Check that it is a valid picture! *)
(*VVV Resize? Crop? *)
    let newname = Ocsigen_lib.make_cryptographic_safe_string () in
    Ol_misc.base64url_of_base64 newname;
    let newpath = !avatar_dir^"/"^newname in
    Unix.link (Eliom_request_info.get_tmp_filename pic) newpath;
    lwt pic = Ol_db.get_pic userid in
    (match pic with
      | None -> ()
      | Some old_pic -> try Unix.unlink (!avatar_dir^"/"^old_pic)
        with Unix.Unix_error _ -> ()
    );
    lwt () = Ol_db.set_pic userid newname in
    Lwt.return newname

  let preregister_action () (m) =
    Ol_misc.log ("OMG:"^m);
    lwt b = Ol_db.is_registered_or_preregistered m in
    Ol_misc.log (string_of_bool b);
    match b with
      | false ->
          Ol_misc.log "NON PREREGISTERED";
          Ol_db.new_preregister_email m
      | true ->
          Ol_misc.log "ALREADY PREREGISTERED";
          Ol_fm.set_flash_msg (Ol_fm.Already_preregistered m)

  (* Admin section *)
  exception Not_admin

  let open_service_handler () () =
    Ol_misc.log "open";
    Ol_site.set_state Ol_site.Production

  let close_service_handler () () =
    Ol_misc.log "close";
    Ol_site.set_state Ol_site.WIP

  let admin_page_content () =
    let open Ol_base_widgets in
    let state_to_string = function
      | Ol_site.WIP -> "work in progress"
      | Ol_site.Production -> "on production"
    in
    lwt state = Ol_site.get_state () in
    let d = Ol_base_widgets.admin_state_choices
              ((state = Ol_site.WIP), close_service)
              ((state = Ol_site.Production), open_service)
    in
      Lwt.return
        ([p [pcdata "welcome admin"];
             p [pcdata (state_to_string state)];
             d])

  let admin_service_handler uid () () =
    lwt user = Ol_db.get_user uid in
    if not (Ol_common0.is_admin user)
     (* should be handle with an exception caught in the Connection_Wrapper ?
      * or just return some html5 stuffs to tell that the user can't reach this
      * page ? (404 ?) *)
    then Lwt.fail Not_admin
    else
      lwt content = admin_page_content () in
      Lwt.return
        (page_container content)

  (********* Registration *********)
  let _ =
    Eliom_registration.Action.register login_service login_action;
    Eliom_registration.Action.register logout_service logout_action;
    Eliom_registration.Action.register preregister_service preregister_action;
    Eliom_registration.Action.register
      lost_password_service lost_password_action;
    Eliom_registration.Action.register
      open_service open_service_handler;
    Eliom_registration.Action.register
      close_service close_service_handler;
    Eliom_registration.Action.register
      sign_up_service sign_up_action;
    Eliom_registration.Any.register activation_service activation_handler;
    Eliom_registration.Action.register
      set_personal_data_service
      (CW.connect_wrapper_function set_personal_data_action);
    Eliom_registration.Ocaml.register get_userlist_for_completion_service
      (CW.connect_wrapper_function get_userlist_for_completion_handler);
    Eliom_registration.Ocaml.register pic_service
      (CW.connect_wrapper_function set_pic);
    My_appl.register admin_service
      (connect_wrapper_page admin_service_handler)

(* Admin service can't be registered here because it belongs
 * to the user application, so the use have to register it by himself. *)

end
