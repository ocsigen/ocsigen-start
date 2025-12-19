(* Ocsigen Start
 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright (C) Université Paris Diderot, CNRS, INRIA, Be Sport.
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

type%shared sms_error_core = [`Unknown | `Send | `Limit | `Invalid_number]
type%shared sms_error = [`Ownership | sms_error_core]

(* adapted from Ocsigen_lib.make_cryptographic_safe_string *)
let activation_code =
  let rng = Cryptokit.Random.device_rng "/dev/urandom" in
  fun () ->
    let random_number = Cryptokit.Random.string rng 5 in
    let n = ref 0L in
    for i = 0 to String.length random_number - 1 do
      n := Int64.(add (shift_left !n 8) (of_int (Char.code random_number.[i])))
    done;
    let n = Int64.(shift_right (Int64.mul !n 10000L) 40) in
    Printf.sprintf "%04Ld" n

let activation_code_ref =
  Eliom_reference.eref ~scope:Eliom_common.default_process_scope None

let recovery_code_ref =
  Eliom_reference.eref ~scope:Eliom_common.default_process_scope None

let send_sms_handler =
  ref @@ fun ~number message ->
  Printf.printf
    "INFO: send SMS %s to %s\nYou have not defined an SMS handler.\nPlease see Os_connect_phone.set_send_sms_handler\n%!"
    message number;
  Error `Send

let set_send_sms_handler = ( := ) send_sms_handler

let send_sms ~number message : (unit, sms_error_core) result =
  !send_sms_handler ~number message

let%server request_code reference number =
  try
    let attempt =
      match Eliom_reference.get reference with
      | Some (_, _, attempt) -> attempt
      | None -> 0
    in
    if attempt <= 3
    then
      let attempt = attempt + 1 and code = activation_code () in
      let () = Eliom_reference.set reference (Some (number, code, attempt)) in
      try (send_sms ~number code :> (unit, sms_error) result)
      with _ -> Error `Send
    else Error `Limit
  with _ -> Error `Unknown

let%server request_wrapper number f =
  if Re.Str.string_match Os_lib.phone_regexp number 0
  then f number
  else Error `Invalid_number

let%rpc request_recovery_code (number : string) : (unit, sms_error) result =
  request_wrapper number @@ fun number ->
  let b = Os_db.Phone.exists number in
  if not b then Error `Ownership else request_code recovery_code_ref number

let%rpc request_code (number : string) : (unit, sms_error) result =
  request_wrapper number @@ fun number ->
  let b = Os_db.Phone.exists number in
  if b then Error `Ownership else request_code activation_code_ref number

let%server confirm_code myid code =
  match Eliom_reference.get activation_code_ref with
  | Some (number, code', _) when code = code' -> Os_db.Phone.add myid number
  | _ -> false

let%rpc confirm_code_extra myid (code : string) : bool = confirm_code myid code

let%server
    confirm_code_signup_no_connect ~first_name ~last_name ~code ~password ()
  =
  match Eliom_reference.get activation_code_ref with
  | Some (number, code', _) when code = code' ->
      let () = Eliom_reference.set activation_code_ref None in
      let user =
        Os_user.create ~password ~firstname:first_name ~lastname:last_name ()
      in
      let userid = Os_user.userid_of_user user in
      let _ = Os_db.Phone.add userid number in
      Some userid
  | _ -> None

let%rpc
    confirm_code_signup
      ~(first_name : string)
      ~(last_name : string)
      ~(code : string)
      ~(password : string)
      () : bool
  =
  match
    confirm_code_signup_no_connect ~first_name ~last_name ~code ~password ()
  with
  | None -> false
  | Some userid ->
      let () = Os_session.connect userid in
      true

let%rpc confirm_code_recovery (code : string) : bool =
  match Eliom_reference.get recovery_code_ref with
  | Some (number, code', _) when code = code' -> (
    match Os_db.Phone.userid number with
    | Some userid ->
        let () = Os_session.connect userid in
        true
    | None -> false)
  | _ -> false

let%rpc connect ~(keepmeloggedin : bool) ~(password : string) (number : string)
  : [`Login_ok | `Wrong_password | `No_such_user | `Password_not_set]
  =
  try
    let userid = Os_db.User.verify_password_phone ~password ~number in
    let () = Os_session.connect ~expire:(not keepmeloggedin) userid in
    `Login_ok
  with
  | Os_db.Empty_password | Os_db.Wrong_password -> `Wrong_password
  | Os_db.No_such_user -> `No_such_user
  | Os_db.Password_not_set -> `Password_not_set
