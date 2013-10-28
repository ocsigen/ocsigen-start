(* Copyright Vincent Balat, Séverine Maingaud *)

(** Main module. Web interaction.
    Definition of service handlers and registration of services. *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

module type ParamT = sig
  type state_t = private [> Eba_types.state_t ] deriving (Json)
  type error_t = private [> Eba_types.error_t ] deriving (Json)
  type notice_t = private [> Eba_types.notice_t ] deriving (Json)

  val app_name : string
  val states : (state_t * string * string option) list

  val page_config : Eba_page.config
  val session_config : Eba_session.config
  val mail_config : Eba_mail.config

  module Database : Eba_database.T
end

module App(M : ParamT) : sig
  module App : sig include Eliom_registration.ELIOM_APPL val app_name : string end
  module User : Eba_user.T
  module Groups : Eba_groups.T
  module Session : Eba_session.T
  module Services : Eba_services.T
  module Page : Eba_page.T
  module Rmsg : Eba_rmsg.T

  module U : Eba_user.T
  module G : Eba_groups.T
  module Ss : Eba_session.T
  module Sv : Eba_services.T
  module R : Eba_rmsg.T
  module P : Eba_page.T
end with type User.t = M.Database.User.ext_t
=
struct
  module App = struct
    include Eliom_registration.App(
    struct
      let application_name = M.app_name
    end)

    let app_name = M.app_name
  end

  module Groups =
    Eba_groups.Make(M.Database.Groups)

      (*
  module Egroups =
    Eba_egroups.Make(struct module Database = Database end)
       *)

  module State = Eba_state.Make(
  struct
    let app_name = M.app_name
    let states = M.states

    type t = M.state_t deriving (Json)
  end)

  module Rmsg = Eba_rmsg.Make(
  struct
    type error_t = M.error_t
    type notice_t = M.notice_t
  end)

  module Mail = Eba_mail.Make(
  struct
    let app_name = M.app_name
    let config = M.mail_config

    module Rmsg = Rmsg
  end)

  module User = Eba_user.Make(
  struct
    include M.Database.User
    module App = App
    module Mail = Mail
    module Rmsg = Rmsg
  end)

  module Session = Eba_session.Make(
  struct
    module Groups = Groups
    module User = User

    let config = M.session_config
  end)

  module Page = Eba_page.Make(
  struct
    let config = M.page_config
    module Session = Session
  end)

  module Services = Eba_services

  module R = Rmsg
  module M = Mail
  module U = User
  module P = Page
  module St = State
  module Ss = Session
  module Sv = Services
  module G = Groups
               (*
  module Eg = Egroups
                *)

  let disconnect_handler () () =
    (* SECURITY: no check here because we disconnect the session cookie owner. *)
    lwt () = Session.disconnect () in
    lwt () = Eliom_state.discard ~scope:Eliom_common.default_session_scope () in
    lwt () = Eliom_state.discard ~scope:Eliom_common.default_process_scope () in
    Eliom_state.discard ~scope:Eliom_common.request_scope ()

  let connect_handler () (login, pwd) =
    (* SECURITY: no check here. *)
    lwt () = disconnect_handler () () in
    match_lwt User.verify_password login pwd with
      | Some uid -> Session.connect uid
      | None ->
          R.Error.push `Wrong_password;
          Lwt.return ()

            (*
  let preregister_handler () email =
    let egroup = Eg.preregister in
    lwt is_in = Eg.in_egroup ~email ~egroup in
    match_lwt User.uid_of_mail email with
      | None ->
          if is_in
          then
            (R.Error.push (`User_already_preregistered email);
             Lwt.return ())
          else
            (R.Notice.push `Preregistered;
             Eg.add_email ~email ~egroup)
      | Some _ ->
          R.Error.push (`User_already_exists email);
          Lwt.return ()
             *)

            (*
  let sign_up_handler () email =
    match_lwt User.uid_of_mail email with
      | None ->
          (*lwt () = Eg.remove_email ~egroup:Egroups.preregister ~email in*)
          lwt act_key = generate_new_key email () in
          lwt _ = User.create ~act_key ~email (User.empty ()) in
          Lwt.return ()
      | Some _ ->
          R.Error.push (`User_already_exists email);
          Lwt.return ()
             *)

  let lost_password_handler () email =
    (* SECURITY: no check here. *)
    match_lwt User.uid_of_email email with
      | None ->
          R.Error.push (`User_does_not_exist email);
          Lwt.return ()
      | Some uid ->
          Lwt.return ()
          (*
           lwt act_key = generate_new_key email () in
           User.attach_activationkey ~act_key uid
           *)

  let set_password_handler userid () (pwd, pwd2) =
    (* SECURITY: We get the userid from session cookie,
       and change personal data for this user. No other check. *)
    if pwd <> pwd2
    then
      (R.Error.push (`Set_password_failed "password does not match");
       Lwt.return ())
    else (
      Lwt.return ())
      (*(User.set userid ~password:pwd ())*)

  let set_personal_data_handler userid ()
      (((firstname, lastname), (pwd, pwd2)) as pd) =
    (* SECURITY: We get the userid from session cookie,
       and change personal data for this user. No other check. *)
    if firstname = "" || lastname = "" || pwd <> pwd2
    then
      (R.Error.push (`Wrong_personal_data pd);
       Lwt.return ())
    else
      Lwt.return ()
        (*
      (User.set
         userid
         ~firstname ~lastname
         ~password:pwd ())
         *)

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
    lwt () = Session.disconnect () in
    match_lwt User.uid_of_activationkey akey with
      | None ->
        (* Outdated activation key *)
        R.Error.push `Activation_key_outdated;
        Eliom_registration.Action.send ()
      | Some uid ->
        (* If the activationkey is valid, we connect the user *)
        lwt () = Session.connect uid in
        Eliom_registration.Redirection.send Eliom_service.void_coservice'

          (*
  module Admin = Eba_admin.Make(
  struct
    module User = User
    module State = State
    module Groups = Groups

    let get_users_from_completion_rpc =
      server_function
        Json.t<string>
        (Session.connect_wrapper_rpc
           (fun uid_connected pattern ->
              Lwt.return []))
              (*User.users_of_pattern pattern))*)

    (** this rpc function is used to change the rights of a user
      * in the admin page *)
    let get_groups_of_user_rpc =
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
           (*
              lwt l = Groups.all () in
              lwt groups = Lwt_list.map_s (group_of_user) l in
            *)
              let groups = [] in
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

    let get_preregistered_emails_rpc =
      server_function
        Json.t<int>
        (Session.connect_wrapper_rpc
           (fun _ n ->
              Lwt.return []))
              (*Egroups.get_emails_in ~egroup:Egroups.preregister ~n))*)

    let create_account_rpc =
      server_function
        Json.t<string>
        (Session.connect_wrapper_rpc
           (fun _ email ->
              (*lwt () = sign_up_handler () email in*)
              Lwt.return ()))

  end)

  module A = Admin
           *)

  (********* Registration *********)
  let _ =
    Eliom_registration.Action.register
      Eba_services.connect_service
      connect_handler;

    Eliom_registration.Action.register
      Eba_services.disconnect_service
      disconnect_handler;

    Eliom_registration.Action.register
      Eba_services.lost_password_service
      lost_password_handler;

    (*
    Eliom_registration.Action.register
      Eba_services.sign_up_service
      sign_up_handler;
     *)

    (*
    Eliom_registration.Action.register
      Eba_services.preregister_service
      preregister_handler;
     *)

    Eliom_registration.Action.register
      Eba_services.set_password_service
      (Session.connect_wrapper_function set_password_handler);

    Eliom_registration.Action.register
      Eba_services.set_personal_data_service
      (Session.connect_wrapper_function set_personal_data_handler);

    Eliom_registration.Any.register
      Eba_services.activation_service
      activation_handler;

    Ew_dyn_upload.register
      Eba_services.crop_service
      (Session.connect_wrapper_function crop_handler);

end
