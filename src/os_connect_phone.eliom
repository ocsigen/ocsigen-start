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

let send_sms_handler = ref @@ fun ~number message ->
  Printf.printf "INFO: send SMS %s to %s\n\
                 You have not defined an SMS handler.\n\
                 Please see Os_connect_phone.set_send_sms_handler\n%!"
    message number;
  Lwt.return (Error `Send)

let set_send_sms_handler = (:=) send_sms_handler

let send_sms ~number message : (unit, sms_error_core) result Lwt.t =
  !send_sms_handler ~number message

let%server request_code reference number =
  try%lwt
    let%lwt attempt =
      match%lwt Eliom_reference.get reference with
      | Some (_, _, attempt) ->
        Lwt.return attempt
      | None ->
        Lwt.return 0
    in
    if attempt <= 3 then
      let attempt = attempt + 1 and code = activation_code () in
      let%lwt () =
        Eliom_reference.set
          reference
          (Some (number, code, attempt))
      in
      try%lwt
        (send_sms ~number code :> (unit, sms_error) result Lwt.t)
      with _ ->
        Lwt.return (Error `Send)
    else
      Lwt.return (Error `Limit)
  with _ ->
    Lwt.return (Error `Unknown)

let%shared request_wrapper f number =
  if Re.Str.string_match Os_lib.phone_regexp number 0 then
    f number
  else
    Lwt.return (Error `Invalid_number)

let%server request_recovery_code = request_wrapper @@ fun number ->
  let%lwt b = Os_db.Phone.exists number in
  if not b then
    Lwt.return (Error `Ownership)
  else
    request_code recovery_code_ref number

let%client request_recovery_code =
  ~%(Eliom_client.server_function
       ~name:"Os_connect_phone.request_recovery_code"
       [%json : string]
       request_recovery_code)

let%server request_code = request_wrapper @@ fun number ->
  let%lwt b = Os_db.Phone.exists number in
  if b then
    Lwt.return (Error `Ownership)
  else
    request_code activation_code_ref number

let%client request_code =
  ~%(Eliom_client.server_function
       ~name:"Os_connect_phone.request_code"
       [%json : string]
       request_code)

let%server confirm_code myid code =
  match%lwt Eliom_reference.get activation_code_ref with
  | Some (number, code', _) when code = code' ->
    Os_db.Phone.add myid number
  | _ ->
    Lwt.return_false

let%server confirm_code_extra =
  Os_session.connected_rpc @@ fun myid code ->
  confirm_code myid code

let%client confirm_code_extra =
  ~%(Eliom_client.server_function
       ~name:"Os_connect_phone.confirm_code_extra"
       Deriving_Json.Json_string.t
       confirm_code_extra)

let%server confirm_code_signup_no_connect
      ~first_name ~last_name ~code ~password () =
  match%lwt Eliom_reference.get activation_code_ref with
  | Some (number, code', _) when code = code' ->
    let%lwt () = Eliom_reference.set activation_code_ref None in
    let%lwt user =
      Os_user.create ~password ~firstname:first_name ~lastname:last_name () in
    let userid = Os_user.userid_of_user user in
    let%lwt b = Os_db.Phone.add userid number in
    Lwt.return_some userid
  | _ ->
    Lwt.return_none

let%server confirm_code_signup (first_name, last_name, code, password) =
  match%lwt
    confirm_code_signup_no_connect ~first_name ~last_name ~code ~password ()
  with
  | None ->
     Lwt.return_false
  | Some userid ->
    let%lwt () = Os_session.connect userid in
    Lwt.return_true

let%client confirm_code_signup =
  ~%(Eliom_client.server_function
       ~name:"Os_connect_phone.confirm_code_signup"
       [%json: string * string * string * string]
       confirm_code_signup)

let%shared confirm_code_signup
    ~first_name ~last_name ~code ~password () =
  confirm_code_signup (first_name, last_name, code, password)

let%server confirm_code_recovery code =
  match%lwt Eliom_reference.get recovery_code_ref with
  | Some (number, code', _) when code = code' ->
    begin
      match%lwt Os_db.Phone.userid number with
      | Some userid ->
        let%lwt () = Os_session.connect userid in
        Lwt.return_true
      | None ->
        Lwt.return_false
    end
  | _ ->
    Lwt.return_false

let%client confirm_code_recovery =
  ~%(Eliom_client.server_function
       ~name:"Os_connect_phone.confirm_code_recovery"
       Deriving_Json.Json_string.t
       confirm_code_recovery)

let%server connect ~keepmeloggedin ~password number =
  try%lwt
    let%lwt userid = Os_db.User.verify_password_phone ~password ~number in
    let%lwt () = Os_session.connect ~expire:(not keepmeloggedin) userid in
    Lwt.return `Login_ok
  with
  | Os_db.Empty_password
  | Os_db.Wrong_password -> Lwt.return `Wrong_password
  | Os_db.No_such_user -> Lwt.return `No_such_user
  | Os_db.Password_not_set -> Lwt.return `Password_not_set

let%client connect =
  let f =
    ~%(Eliom_client.server_function ~name:"Os_connect_phone.connect"
         [%json: string * string * bool]
         (Os_session.Opt.connected_rpc
            (fun _ (number, password, keepmeloggedin) ->
               connect ~keepmeloggedin ~password number)))
  in
  fun ~keepmeloggedin ~password number -> f (number, password, keepmeloggedin)
