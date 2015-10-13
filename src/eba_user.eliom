(* This file is part of Eliom-base-app.
   Feel free to use it, modify it according to your needs,
   and redistribute it as you wish. *)

open Eliom_content.Html5.F

exception Already_exists of int64
exception No_such_user

{shared{
  (** The type which represents a user. *)
  type t = {
    userid : int64;
    fn : string;
    ln : string;
    avatar : string option;
  } deriving (Json)
}}

(** Create a user of type [t] using db informations. *)
let create_user_from_db0 (userid, fn, ln, avatar, pwdset) =
  {
    userid = userid;
    fn = fn;
    ln = ln;
    avatar = avatar;
  },
  pwdset

let create_user_from_db d = fst (create_user_from_db0 d)

{shared{
(** Getters functions. *)
let userid_of_user u = u.userid
let firstname_of_user u = u.fn
let lastname_of_user u = u.ln
let avatar_of_user u = u.avatar

let avatar_uri_of_avatar avatar =
  Eliom_content.Html5.F.make_uri
    ~service:(Eliom_service.static_dir ()) ["avatars"; avatar]

let avatar_uri_of_user user =
  Eliom_lib.Option.map avatar_uri_of_avatar (avatar_of_user user)

let fullname_of_user user = String.concat " " [user.fn; user.ln]

let is_complete u = not (u.fn = "" || u.ln = "")

}}
let emails_of_user user = Eba_db.User.emails_of_userid user.userid
let email_of_user user = Eba_db.User.email_of_userid user.userid


include Eba_db.User

(* Using cache tools to prevent multiple same database queries
   during the request. *)
module MCache = Eba_request_cache.Make(
struct
  type key = int64
  type value = t * bool

  let compare = compare
  let get key =
    try_lwt
      lwt g = Eba_db.User.user_of_userid key in
      Lwt.return (create_user_from_db0 g)
    with Eba_db.No_such_resource -> Lwt.fail No_such_user
end)

(* Overwrite the function [user_of_userid] of [Eba_db.User] and use
   the [get] function of the cache module. *)
let user_of_userid userid =
  lwt u, _ = MCache.get userid in
  Lwt.return u

let password_set userid =
  lwt _, s = MCache.get userid in
  Lwt.return s




(* -----------------------------------------------------------------

   All the followings functions are only helpers/wrappers around db
   functions ones. They generally use the type [t] of the module
   and get rid of the part of picking each field of the record [t].

*)

let empty = {
  userid = 0L;
  fn = "";
  ln = "";
  avatar = None;
}

(** Create new user. May raise [Already_exists] *)
let create ?password ?avatar ~firstname ~lastname email =
  try_lwt
    lwt userid = Eba_db.User.userid_of_email email in
    Lwt.fail (Already_exists userid)
  with Eba_db.No_such_resource ->
    lwt userid =
      Eba_db.User.create ~firstname ~lastname ?password ?avatar email
    in
    user_of_userid userid

(* Overwrites the function [update] of [Eba_db.User]
   to reset the cache *)
let update ?password ?avatar ~firstname ~lastname userid =
  lwt () = Eba_db.User.update
             ?password ?avatar ~firstname ~lastname userid
  in
  MCache.reset userid;
  Lwt.return ()

let update' ?password t =
  update ?password ?avatar:t.avatar ~firstname:t.fn ~lastname:t.ln t.userid

let update_password password userid =
  lwt () = Eba_db.User.update_password password userid in
  MCache.reset userid;
  Lwt.return ()

let update_avatar avatar userid =
  lwt () = Eba_db.User.update_avatar avatar userid in
  MCache.reset userid;
  Lwt.return ()

let get_users ?pattern () =
  lwt users = Eba_db.User.get_users ?pattern () in
  Lwt.return (List.map create_user_from_db users)

let set_pwd_crypt_fun a = Eba_db.pwd_crypt_ref := a

let generate_act_key
    ?(act_key = Ocsigen_lib.make_cryptographic_safe_string ())
    ?(send_email = true)
    ~service
    ~text
    email =
  let service =
    Eliom_service.attach_coservice' ~fallback:service
      ~service:Eba_services.activation_service
  in
  let act_link = Eliom_content.Html5.F.make_string_uri ~absolute:true ~service act_key in
  (* For debugging we print the activation link on standard output
     to make possible to connect even if the mail transport is not
     configured. *)
  if Ocsigen_config.get_debugmode ()
  then print_endline ("Debug: activation link created: "^act_link);
  if send_email
  then
    Lwt.async (fun () ->
      try_lwt
        Eba_email.send
          ~to_addrs:[("", email)]
          ~subject:"creation"
          [
            text;
            act_link;
          ]
      with _ -> Lwt.return ());
  act_key

let send_act msg service email =
  let act_key =
    generate_act_key
      ~service:service
      ~text:msg
      email
  in
  Eliom_reference.Volatile.set Eba_msg.activation_key_created true;
  lwt () = add_activationkey ~act_key email in
  Lwt.return ()

let send_mail_confirmation email =
  let msg =
    "Welcome!\r\nTo confirm your e-mail address, \
     please click on this link: " in
  send_act msg Eba_services.main_service email
