(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
 *
 * Copyright 2014
 *      Charly Chevalier
 *      Vincent Balat
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

(** Registration of default services *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

let set_personal_data_handler' userid ()
    (((firstname, lastname), (pwd, pwd2)) as pd) =
  if firstname = "" || lastname = "" || pwd <> pwd2
  then
    (Eliom_reference.Volatile.set Eba_msg.wrong_pdata (Some pd);
     Lwt.return ())
  else (
    lwt user = Eba_user.user_of_userid userid in
    let open Eba_user in
    let record = {
      user with
      fn = firstname;
      ln = lastname;
    } in
    Eba_user.update' ~password:pwd record)

let set_password_handler' userid () (pwd, pwd2) =
  if pwd <> pwd2
  then
    (Eba_msg.msg ~level:`Err "Passwords do not match";
     Lwt.return ())
  else (
    lwt user = Eba_user.user_of_userid userid in
    Eba_user.update' ~password:pwd user)

let sign_up_handler' () email =
  let send_act userid = Eba_user.send_mail_confirmation userid email in
  try_lwt
    lwt u = Eba_user.create ~firstname:"" ~lastname:"" email in
    send_act u.Eba_user.userid
  with Eba_user.Already_exists userid ->
    (* If password is not set, the user probably never logged in,
       I send an activation link, as if it were a new user. *)
    lwt pwdset = Eba_user.password_set userid in
    if not pwdset
    then send_act userid
    else begin
      Eliom_reference.Volatile.set Eba_userbox.user_already_exists true;
      Lwt.return ()
    end

let forgot_password_handler service () (email, primary_email) =
  (* First we need to find the user that tries to
     reset its password.
     To do so, we try to find the user with 'email':
     - if there is a unique user that activated 'email',
       we're done (we still check that the primary_email
       of that user is 'primary_email', if 'primary_email' was
       set by the user asking to reset the password).
     - else, we choose among these users, the one that has
       'primary_email' as primary_email. *)
  let find_userid () =
    lwt userids = Eba_user.userids_that_activated_email email in
    lwt primary_userid =
      if primary_email = "" then Lwt.return None
      else
        lwt userid = Eba_user.userid_of_primary_email primary_email in
        Lwt.return (Some userid)
    in
    match userids with
    | [] -> raise Eba_db.No_such_resource
    | hd :: tl ->
       match tl with
       | [] -> begin
          match primary_userid with
          | None -> Lwt.return hd
          | Some userid ->
             if userid = hd then Lwt.return hd
             else Lwt.fail (Eba_db.No_such_resource)
         end
       | _ ->
          match primary_userid with
          | None -> Lwt.fail (Eba_db.No_such_resource)
          | Some userid ->
             try
               let res = List.find (fun x -> x = userid) userids in
               Lwt.return res
             with Not_found -> Lwt.fail (Eba_db.No_such_resource)
  in
  try_lwt
    lwt userid = find_userid () in
    let msg = "Hi,\r\nTo set a new password, \
               please click on this link: " in
    Eba_user.send_act msg service userid email
  with Eba_db.No_such_resource ->
    Eliom_reference.Volatile.set
      Eba_userbox.user_does_not_exist true;
    Lwt.return ()


let disconnect_handler () () =
  (* SECURITY: no check here because we disconnect the session cookie owner. *)
  Eba_session.disconnect ()

let connect_handler () ((login, pwd), keepmeloggedin) =
  (* SECURITY: no check here.
     We disconnect the user in any case, so that he does not believe
     to be connected with the new account if the password is wrong. *)
  lwt () = disconnect_handler () () in
  try_lwt
    lwt userid = Eba_user.verify_password login pwd in
    let expire =
      if keepmeloggedin then
        Some (Unix.time() +. 315532800.)
      else None in
    Eba_session.connect ?expire userid
  with Eba_db.No_such_resource ->
    Eliom_reference.Volatile.set Eba_userbox.wrong_password true;
    Lwt.return ()

let activation_handler akey () =
  (* SECURITY: we disconnect the user before doing anything. *)
  (* If the user is already connected,
     we're going to disconnect him even if the activation key outdated. *)
  try_lwt
    lwt userid, email, is_primary =
                         Eba_user.userid_email_is_primary_of_activationkey
                           akey in
    lwt () =
      lwt () =
        if not is_primary then
           (* in that case we activate the mail *)
          Eba_user.activate_email userid email
        else Lwt.return_unit
      in
      lwt () = Eba_session.disconnect () in
      Eba_session.connect userid
    in
    Eliom_registration.Redirection.send Eliom_service.void_coservice'
  with Eba_db.No_such_resource ->
    Eliom_reference.Volatile.set
      Eba_userbox.activation_key_outdated true;
    (*VVV This should be a redirection, in order to erase the outdated URL.
      But we do not have a simple way of
      writing an error message after a redirection for now.*)
    Eliom_registration.Action.send ()

          (*
let admin_service_handler userid gp pp =
  lwt user = Eba_user.user_of_userid userid in
  (*lwt cnt = Admin.admin_page_content user in*)
  %%%MODULE_NAME%%%_container.page [
  ] (*@ cnt*)
           *)

let preregister_handler' () email =
  lwt is_preregistered = Eba_user.is_preregistered email in
  lwt is_registered = Eba_user.is_registered email in
  Printf.printf "%b:%b%!\n" is_preregistered is_registered;
  if not (is_preregistered || is_registered)
   then Eba_user.add_preregister email
   else begin
     Eliom_reference.Volatile.set
       Eba_userbox.user_already_preregistered true;
     Lwt.return ()
   end


{shared{
   let _ = Eba_comet.__link (* to make sure eba_comet is linked *)
}}
