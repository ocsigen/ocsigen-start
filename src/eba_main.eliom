(* Copyright Vincent Balat, Séverine Maingaud *)

(** Main module. Web interaction.
    Definition of service handlers and registration of services. *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

module type T = sig
  type state_t = private [> Eba_types.state_t ] deriving (Json)
  type error_t = private [> Eba_types.error_t ] deriving (Json)
  type notice_t = private [> Eba_types.notice_t ] deriving (Json)

  val app_name : string
  val states : (state_t * string * string option) list

  val page_config : Eba_page.config
  val session_config : Eba_session.config
  val mail_config : Eba_mail.config
  val db_config : Eba_db.config
end

module App(M : T) = struct

  module App = struct
    include Eliom_registration.App (struct let application_name = M.app_name end)

    let app_name = M.app_name
  end

  module Database = Eba_db.Make(struct
                                  let config = M.db_config
                                end)
  module D = Database

  module Groups = struct
    include Eba_groups.Make(struct module Database = Database end)
  end
  module G = Groups

  module User = struct
    include Eba_user.Make(struct module Database = Database end)
  end
  module U = User

  module State = Eba_state.Make(struct
                               let app_name = M.app_name
                               let states = M.states

                               type t = M.state_t deriving (Json)
                             end)
  module St = State

  module Admin = Eba_admin.Make(struct
                                  module User = User
                                  module State = State
                                  module Groups = Groups
                                end)
  module A = Admin
(*
*)

  module Session = Eba_session.Make(struct
                                       module Database = Database
                                       module Groups = Groups
                                       module User = User
                                       let config = M.session_config
                                     end)
  module Ss = Session

  module Page = Eba_page.Make(struct
                                let config = M.page_config
                                module Session = Ss
                              end)
  module P = Page

  module Services = Eba_services
  module Sv = Services

  module View = Eba_view.Make(struct
                                module User = User
                              end)
  module V = View

  (* *)

  module Rmsg = Eba_rmsg.Make(struct
                                type error_t = M.error_t
                                type notice_t = M.notice_t
                              end)
  module R = Rmsg

  module Mail = Eba_mail.Make(struct
                                let app_name = M.app_name
                                let config = M.mail_config

                                module Rmsg = Rmsg
                              end)

  module Default = struct
    include Eba_form
  end

  let logout_handler () () =
    (* SECURITY: no check here because we logout the session cookie owner. *)
    lwt () = Session.logout () in
    lwt () = Eliom_state.discard ~scope:Eliom_common.default_session_scope () in
    lwt () = Eliom_state.discard ~scope:Eliom_common.default_process_scope () in
    Eliom_state.discard ~scope:Eliom_common.request_scope ()

  let login_handler () (login, pwd) =
    (* SECURITY: no check here. *)
    lwt () = logout_handler () () in
    try_lwt
      lwt userid = User.verify_password login pwd in
      Session.connect userid
    with _ -> (* TODO: Not_found exception *)
      R.Error.push `Wrong_password;
      Lwt.return ()

  let send_activation_email ~email ~uri () =
    try_lwt
      ignore (Netaddress.parse email);
      Mail.send
        ~to_addrs:[email]
        ~subject:(M.app_name^" registration")
        (fun app_name ->
           Lwt.return
             [
               "To activate your "^app_name^" account, please visit the following link:";
               uri;
               "\n";
               "This is an auto-generated message. ";
               "Please do not reply."
             ])
    with
      | _ -> (* TODO: get informations from exception and forward them into
              * `Send_mail_failed rmsg *)
          R.Error.push `Send_mail_failed;
          Lwt.return false

  (** will generate an activation key which can be used to login
      directly. This key will be send to the [email] address *)
  let generate_new_key email service gp =
    let act_key = Ocsigen_lib.make_cryptographic_safe_string () in
    let service =
      Eliom_service.attach_coservice'
        ~fallback:service
        ~service:Eba_services.activation_service
    in
    let uri =
      Eliom_content.Html5.F.make_string_uri ~absolute:true ~service act_key
    in
    let echo = print_endline in
    let for_ = "for the user ["^email^"]" in
    echo ("Here, the new activation key "^for_^": "^uri);
    lwt ret = send_activation_email ~email ~uri () in
    (* TODO: log errors differently than notice log -> create a Log module ? *)
    if ret
    then echo ("The activation email "^for_^" has been sent.")
    else echo ("The activation email "^for_^" has not been sent.");
    R.Notice.push `Activation_key_created;
    Lwt.return act_key

  let sign_up_handler () email =
    match_lwt User.uid_of_mail email with
      | None ->
          lwt act_key = generate_new_key email Eba_services.main_service () in
          lwt _ = User.create ~act_key email in
          Lwt.return ()
      | Some _ ->
          R.Error.push (`User_already_exists email);
          Lwt.return ()

  let lost_password_handler () email =
    (* SECURITY: no check here. *)
    match_lwt User.uid_of_mail email with
      | None ->
          R.Error.push (`User_does_not_exist email);
          Lwt.return ()
      | Some uid ->
          lwt act_key = generate_new_key email Eba_services.main_service () in
          User.set uid ~act_key ()

  let set_password_handler userid () (pwd, pwd2) =
    (* SECURITY: We get the userid from session cookie,
       and change personal data for this user. No other check. *)
    if pwd <> pwd2
    then
      (R.Error.push (`Set_password_failed "password does not match");
       Lwt.return ())
    else (User.set userid ~password:pwd ())

  let set_personal_data_handler userid ()
      (((firstname, lastname), (pwd, pwd2)) as pd) =
    (* SECURITY: We get the userid from session cookie,
       and change personal data for this user. No other check. *)
    if firstname = "" || lastname = "" || pwd <> pwd2
    then
      (R.Error.push (`Wrong_personal_data pd);
       Lwt.return ())
    else
      (User.set
         userid
         ~firstname ~lastname
         ~password:pwd ())

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
    * Session.connect_wrapper_function *)
  let activation_handler akey () =
    (* SECURITY: we disconnect the user before doing anything
     * moreover in this case, if the user is already disconnect
     * we're going to disconnect him even if the actionvation key
     * is outdated. *)
    lwt () = Session.logout () in
    lwt () = match_lwt User.uid_of_activationkey akey with
      | None ->
         (* Outdated activation key *)
          print_endline "invalid act key";
          R.Error.push `Activation_key_outdated;
          Lwt.return ()
      | Some uid ->
         (* If the activationkey is valid, we connect the user *)
          Session.connect uid
    in
    Lwt.return ()
    (*Eliom_registration.Redirection.send Eliom_service.void_coservice'*)

  let get_users_from_completion_rpc
        : (string, (User.t list)) Eliom_pervasives.server_function
        =
    server_function
      Json.t<string>
      (Session.connect_wrapper_rpc
         (fun uid_connected pattern ->
            User.users_of_pattern pattern))

  (** this rpc function is used to change the rights of a user
    * in the admin page *)
  let get_groups_of_user_rpc
        : (int64, ((Groups.t * bool) list)) Eliom_pervasives.server_function
        =
    server_function
      Json.t<int64>
      (Session.connect_wrapper_rpc
         (fun uid_connected uid ->
            let group_of_user group =
              (*Eba_misc.log (Groups.name_of group);*)
              (* (t: group * boolean: the user belongs to this group) *)
              lwt in_group = Groups.in_group ~userid:uid ~group in
              Lwt.return (group, in_group)
            in
            lwt l = Groups.all () in
            lwt groups = Lwt_list.map_s (group_of_user) l in
            (*List.iter (fun (a,b) -> Printf.printf "(%s, %b)" (Groups.name_of a) (b)) groups;*)
            Lwt.return groups))

  (** this rpc function is used to change the rights of a user
    * in the admin page *)
  let set_group_of_user_rpc =
    server_function
      Json.t<int64 * (bool * Eba_types.Groups.t)>
      (Session.connect_wrapper_rpc
         (fun uid_connected (uid, (set, group)) ->
            lwt () =
              if set
              then Groups.add_user ~userid:uid ~group
              else Groups.remove_user ~userid:uid ~group
            in
            Lwt.return ()))

  (********* Registration *********)
  let _ =
    Eliom_registration.Action.register
      Eba_services.login_service
      login_handler;

    Eliom_registration.Action.register
      Eba_services.logout_service
      logout_handler;

    Eliom_registration.Action.register
      Eba_services.lost_password_service
      lost_password_handler;

    Eliom_registration.Action.register
      Eba_services.sign_up_service
      sign_up_handler;

    Eliom_registration.Action.register
      Eba_services.set_password_service
      (Session.connect_wrapper_function set_password_handler);

    Eliom_registration.Action.register
      Eba_services.set_personal_data_service
      (Session.connect_wrapper_function set_personal_data_handler);

    (* FIXME: We don't use Eliom_registration.Action here, otherwise the
     * activation key is not removed from the URL. Using Eliom_registration.Any
     * and an explicit redirection to a void_coservice' do the trick of
     * removing the activation key. Any other suggestions to clean the URL ?
     *
     * btw, in the future, we should use Eliom_registration.Action.
     * *)
    Eliom_registration.Action.register
      Eba_services.activation_service
      activation_handler;

    Ew_dyn_upload.register
      Eba_services.crop_service
      (Session.connect_wrapper_function crop_handler);

(*
    Eliom_registration.Action.register preregister_service
      Eba_preregister.preregister_handler;
*)

    App.register
      Eba_services.admin_service
      (Page.connected_page
         (Admin.admin_service_handler
            set_group_of_user_rpc
            get_users_from_completion_rpc
            get_groups_of_user_rpc));

end
