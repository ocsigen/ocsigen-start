(* Copyright Vincent Balat, Séverine Maingaud *)

(** Main module. Web interaction.
    Definition of service handlers and registration of services. *)

{shared{
open Eliom_content.Html5
open Eliom_content.Html5.F
}}
open Eba_services

module Eba_fm = Eba_flash_message

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

  module CW = Eba_sessions.Connect_Wrappers(A)

  include CW

  let main_title = Eba_site_widgets.main_title A.capitalized_app_name

  module My_appl =
    Eliom_registration.App (
      struct
        let application_name = A.app_name
      end)


  (********* Service handlers *********)
  let page_container content =
    let css = List.map (fun cssname -> ("css"::cssname))
                ([["eliom_ui.css"];
                  ["ol.css"]; (* merge them together *)
                  ["eba.css"];
                  ["popup.css"];
                  ["jcrop.css"];
                  ["jquery.Jcrop.css"]]
                @ A.css_list)
    in
    let js = List.map (fun jsname -> ("js"::jsname))
               ([["jquery.js"];
                 ["jquery.Jcrop.js"];
                 ["jquery.color.js"]]
               @ A.js_list)
    in
    (html
       (Eliom_tools.F.head ~title:A.capitalized_app_name ~css ~js ())
       (body content))

  let error_page msg =
    Lwt.return (page_container
                  [main_title;
                   Eba_site_widgets.mainpart
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
      lwt userid = Eba_db.check_pwd login pwd in
      CW.connect userid
    with Not_found ->
      Eba_fm.set_flash_msg Eba_fm.Wrong_password;
      Lwt.return ()

  let login_page _ _ =
    lwt cb = Eba_base_widgets.login_signin_box () in
    Lwt.return
      (page_container
         [div
             ~a:[a_class ["ol_welcomepage"]]
             [main_title; cb]])

let send_activation_email ~email ~uri () =
  try_lwt
    ignore (Netaddress.parse email);
    Eba_misc.send_mail
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
  let generate_new_key email service gp =
    let activationkey = Ocsigen_lib.make_cryptographic_safe_string () in
    lwt () = Eba_db.new_activation_key email activationkey in
    let service = Eliom_service.attach_coservice'
                       ~fallback:service
                       ~service:activation_service
    in
    let uri = Eliom_content.Html5.F.make_string_uri
                ~absolute:true
                ~service
                activationkey
    in
    (*VVV REMOOOOOOOOOOOOOOOOOOOVE! *)
    Eba_misc.log ("REMOVE ME activation link: "^uri);
    lwt _ = send_activation_email ~email ~uri () in
    Eliom_reference.Volatile.set Eba_sessions.activationkey_created true;
    Lwt.return ()

  let sign_up_action () email =
    match_lwt Eba_db.user_exists email with
      | false -> generate_new_key email Eba_services.main_service ()
      | true ->
          Eba_fm.set_flash_msg (Eba_fm.User_already_exists email);
          Lwt.return ()

  let lost_password_action () email =
    (* SECURITY: no check here. *)
    match_lwt Eba_db.user_exists email with
      | true -> generate_new_key email Eba_services.main_service ()
      | false ->
          Eba_fm.set_flash_msg (Eba_fm.User_does_not_exist email);
          Lwt.return ()


  let connect_wrapper_page ?allow ?deny f gp pp =
    CW.gen_wrapper ~allow ~deny f login_page gp pp

  let new_user user = user.Eba_common0.new_user


  let set_password_handler userid () (pwd, pwd2) =
    (* SECURITY: We get the userid from session cookie,
       and change personal data for this user. No other check. *)
    if pwd <> pwd2
    then
      ((* TODO flash message ? *)
      Lwt.return ())
    else
      let pwd = Bcrypt.hash pwd in
      Eba_db.set_password userid (Bcrypt.string_of_hash pwd)


  let set_personal_data_action userid ()
      (((firstname, lastname), (pwd, pwd2)) as v) =
    (* SECURITY: We get the userid from session cookie,
       and change personal data for this user. No other check. *)
    if firstname = "" || lastname = "" || pwd <> pwd2
    then (Eliom_reference.Volatile.set Eba_sessions.wrong_perso_data (Some v);
          Lwt.return ())
    else let pwd = Bcrypt.hash pwd in
         Eba_db.set_personal_data userid firstname lastname (Bcrypt.string_of_hash pwd)


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

  let crop_handler userid gp pp =
    let dynup_handler =
      (* Will return a function which takes GET and POST parameters *)
      Ew_dyn_upload.handler
        ~dir:["avatars"]
        ~remove_on_timeout:true
        ~extensions:["png"; "jpg"]
        (fun dname fname ->
           let path = List.fold_left (fun a b -> a^"/"^b) "./static" dname in
           let path = path^"/"^fname in
           let img = Magick.read_image path in
           let w,h =
             Magick.get_image_width img,
             Magick.get_image_height img
           in
           let resize w h =
             Magick.Imper.resize
               img
               ~width:w
               ~height:h
               ~filter:Magick.Point
               ~blur:0.0
           in
           let ratio w h new_w =
             let iof,foi = int_of_float,float_of_int in
               iof ((foi h) /. (foi w) *. (foi new_w))
           in
           let normalize n max =
             n * 100 / max
           in
           let w_max,h_max = 700,500 in
           let () =
             if w > w_max || h > h_max
             then
               if (normalize w w_max) > (normalize h h_max)
               then resize w_max (ratio w h w_max)
               else resize (ratio h w h_max) h_max
           in
           let () = Magick.write_image img ~filename:path in
           Lwt.return ())
    in
    dynup_handler gp pp

  (** service which will be attach to the current service to handle
    * the activation key (the attach_coservice' will be done on
    * connect_wrapper_function *)
  let activation_handler akey () =
    (* SECURITY: we disconnect the user before doing anything
     * moreover in this case, if the user is already disconnect
     * we're going to disconnect him even if the actionvation key
     * is outdated. *)
    lwt () = CW.logout () in
    try_lwt
      (* If the activationkey is valid, we connect the user *)
      lwt userid = Eba_db.get_userid_from_activationkey akey in
      lwt () = CW.connect userid in
      Eliom_registration.Redirection.send Eliom_service.void_coservice'
    with Not_found -> (* outdated activation key *)
      (*CHARLY: not connected (using flash
       * message to display an error ?) *)
      Eba_fm.set_flash_msg Eba_fm.Activation_key_outdated;
      lwt page = login_page () () in
      My_appl.send page

  (** this rpc function is used to change the rights of a user
    * in the admin page *)
  let get_groups_of_user_rpc
        : (int64, ((Eba_groups.t * bool) list)) Eliom_pervasives.server_function
        =
    server_function
      Json.t<int64>
      (CW.connect_wrapper_rpc
         (fun uid_connected uid ->
            let group_of_user group =
              Eba_misc.log (Eba_groups.name_of group);
              (* (t: group * boolean: the user belongs to this group) *)
              lwt in_group = Eba_groups.in_group ~userid:uid ~group in
               Lwt.return (group, in_group)
            in
            lwt l = Eba_groups.all () in
            lwt groups = Lwt_list.map_s (group_of_user) l in
    List.iter (fun (a,b) -> Printf.printf "(%s, %b)" (Eba_groups.name_of a) (b)) groups;
            let () = Eba_misc.log "return mec !" in
              Lwt.return groups))

  (** this rpc function is used to change the rights of a user
    * in the admin page *)
  let set_group_of_user_rpc =
    server_function
      Json.t<int64 * (bool * Eba_groups.t)>
      (CW.connect_wrapper_rpc
         (fun uid_connected (uid, (set, group)) ->
            lwt () =
              if set
              then Eba_groups.add_user ~userid:uid ~group
              else Eba_groups.remove_user ~userid:uid ~group
            in
              Lwt.return ()))


  (********* Registration *********)
  let _ =
    Eliom_registration.Action.register login_service login_action;
    Eliom_registration.Action.register logout_service logout_action;
    (*
    Eliom_registration.Action.register preregister_service
      Eba_preregister.preregister_action;
     *)
    Eliom_registration.Action.register
      lost_password_service lost_password_action;
    Eliom_registration.Action.register
      sign_up_service sign_up_action;
    Eliom_registration.Any.register activation_service activation_handler;
    Eliom_registration.Action.register
      set_password_service
      (CW.connect_wrapper_function set_password_handler);
    Eliom_registration.Action.register
      set_personal_data_service
      (CW.connect_wrapper_function set_personal_data_action);
    Eliom_registration.Action.register
      open_service Eba_admin.open_service_handler;
    Eliom_registration.Action.register
      close_service Eba_admin.close_service_handler;
    Ew_dyn_upload.register
      crop_service
      (CW.connect_wrapper_function crop_handler);
    My_appl.register admin_service
      (connect_wrapper_page
         (Eba_admin.admin_service_handler
            page_container
            main_title
            set_group_of_user_rpc
            get_groups_of_user_rpc));

(* Admin service can't be registered here because it belongs
 * to the user application, so the use have to register it by himself. *)

end
