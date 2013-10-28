{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

exception No_such_user

module type T = sig
  type basic_t = Eba_types.User.basic_t
  type t

  val explicit_reset_uid_from_cache : int64 -> unit

  (*val create : ?password:string -> act_key:string -> email:string -> ext_t -> int64 Lwt.t*)
  val create : ?password:string
            -> email:string
            -> ?service:(unit, unit,
                         [ `Attached of
                            ([ `Internal of [> `Service ] ], [`Get ])
                              Eliom_service.a_s ],
                         [ `WithoutSuffix ], unit, unit,
                         [< Eliom_service.registrable > `Registrable ],
                         [> Eliom_service.appl_service ])
                 Eliom_service.service
            (* -> ?get: TODO *)
            -> ?act_key:string
            -> ?act_email_content:(string -> string -> string list Lwt.t)
            -> ?act_email_subject:string
            -> t
            -> int64 Lwt.t

  val update : ?password:string -> t Eba_types.User.ext_t -> unit Lwt.t
  val attach_activationkey : ?act_key:string -> int64 -> unit Lwt.t

  val basic_user_of_uid : int64 -> basic_t Lwt.t
  val user_of_uid : int64 -> t Eba_types.User.ext_t Lwt.t

  val uid_of_email : string -> int64 option Lwt.t
  val uid_of_activationkey : string -> int64 option Lwt.t

  include Eba_shared.TUser
end

module Make(M : sig
  include Eba_database.Tuser
  module App : sig include Eliom_registration.ELIOM_APPL val app_name : string end
  module Mail : Eba_mail.T
  module Rmsg : Eba_rmsg.T
end)
  =
struct
  type t = M.ext_t
  type basic_t = Eba_types.User.basic_t

  include Eba_shared.User

  module MCache = Eba_tools.Cache_f.Make(
  struct
    type key_t = int64
    type value_t = t Eba_types.User.ext_t

    let compare = compare
    let get key =
      match_lwt M.user_of_uid key with
        | Some u -> Lwt.return u
        | None -> Lwt.fail No_such_user
  end)

  let explicit_reset_uid_from_cache uid =
    MCache.reset (uid :> int64)

  let default_act_key = Ocsigen_lib.make_cryptographic_safe_string

  let default_act_email_subject = M.App.app_name^ "registration"
  let default_act_email_content act_key app_name =
    Lwt.return [
      "To activate your "^app_name^" account, please visit the following link:";
      act_key;
      "";
      "This is an auto-generated message.";
      "Please do not reply."
    ]

  let send_activation_email ~act_key ~subject ~email cnt_fn =
    try_lwt
      ignore (Netaddress.parse email);
      lwt ret =
        M.Mail.send ~to_addrs:[email]
          ~subject
          (cnt_fn act_key)
      in
      Lwt.return ret
    with _ ->
      M.Rmsg.Error.push (`Send_mail_failed "invalid e-mail address");
      Lwt.return false

  let create ?password ~email
        ?(service = Eba_services.main_service)
        (*?(get = ()) TODO *)
        ?(act_key = default_act_key ())
        ?(act_email_content = default_act_email_content)
        ?(act_email_subject = default_act_email_subject)
        ext =
    match_lwt M.uid_of_email email with
     | Some uid -> Lwt.return uid
     | None ->
         lwt uid = M.new_user ?password ~email ext in
         let service =
           Eliom_service.attach_coservice'
             ~fallback:service
             ~service:Eba_services.activation_service
         in
         let act_key' = F.make_string_uri ~absolute:true ~service act_key in
         lwt () = M.attach_activationkey ~act_key uid in
         lwt _ =
           send_activation_email
             ~email ~act_key:act_key'
             ~subject:act_email_subject
             act_email_content
         in
         M.Rmsg.Notice.push `Activation_key_created;
         Lwt.return uid

  let attach_activationkey ?(act_key = default_act_key ()) uid =
    M.Rmsg.Notice.push `Activation_key_created;
    M.attach_activationkey ~act_key uid

  let update ?password user =
    M.update ?password user

  let verify_password email passwd =
    M.verify_password email passwd

  let uid_of_email email =
    M.uid_of_email email

  let uid_of_activationkey act_key =
    M.uid_of_activationkey act_key

  let user_of_uid uid =
    ((MCache.get uid) :> t Eba_types.User.ext_t Lwt.t)

  let basic_user_of_uid uid =
    lwt u = MCache.get uid in
    let open Eba_types.User in
    Lwt.return ({
      uid = (uid_of_user u);
      ext = ();
    } :> basic_t)
end

open Eliom_content.Html5
open Eliom_content.Html5.F

(* FIXME: the followings should be in another module I think, it concerns
 * only css/style, and should be maybe, into a "view" user module *)
{shared{
  let cls_avatar = "eba_avatar"
  let cls_mail = "eba_avatar"
  let cls_user = "eba_user"
  let cls_users = "eba_users"
  let cls_user_box = "eba_user_box"
}}
