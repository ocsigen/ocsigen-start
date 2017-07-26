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

type%shared sms_error_core = [`Unknown | `Send | `Limit]
type%shared sms_error = [`Duplicate_number | sms_error_core]

(* adapted from Ocsigen_lib.make_cryptographic_safe_string *)
let activation_code =
  let rng = Cryptokit.Random.device_rng "/dev/urandom" in
  fun () ->
    let random_number = Cryptokit.Random.string rng 20 in
    let to_b64 = Cryptokit.Base64.encode_compact () in
    (* CHECKME: is this cryptographically safe? probably not *)
    String.uppercase_ascii
      (String.sub (Cryptokit.transform_string to_b64 random_number) 0 6)

let activation_code_ref =
  Eliom_reference.eref ~scope:Eliom_common.default_process_scope None

let store_activation_code ~attempt ~number code =
  Eliom_reference.set activation_code_ref (Some (number, code, attempt))

let send_sms_handler = ref @@ fun ~number message ->
  Printf.printf "INFO: send SMS %s to %s\n\
                 You have not defined an SMS handler.\n\
                 Please see Os_connect_phone.set_send_sms_handler\n%!"
    message number;
  Lwt.return (Error `Send)

let set_send_sms_handler = (:=) send_sms_handler

let send_sms ~number message : (unit, sms_error_core) result Lwt.t =
  !send_sms_handler ~number message

let%server request_activation_code number =
  let%lwt b = Os_db.Phone.exists number in
  if b then
    Lwt.return (Error `Duplicate_number)
  else
    try%lwt
      let%lwt attempt =
        match%lwt Eliom_reference.get activation_code_ref with
        | Some (_, _, attempt) ->
          Lwt.return attempt
        | None ->
          Lwt.return 0
      in
      if attempt <= 3 then
        let attempt = attempt + 1 and code = activation_code () in
        let%lwt () = store_activation_code ~number ~attempt code in
        try%lwt
          (send_sms ~number code :> (unit, sms_error) result Lwt.t)
        with _ ->
          Lwt.return (Error `Send)
      else
        Lwt.return (Error `Limit)
    with _ ->
      Lwt.return (Error `Unknown)

let%client request_activation_code =
  ~%(Eliom_client.server_function [%derive.json : string]
       request_activation_code)

let reset_activation_code () =
  let%lwt v  = Eliom_reference.get activation_code_ref in
  let%lwt () = Eliom_reference.set activation_code_ref None in
  Lwt.return v

let%server confirm_activation_code =
  Os_session.connected_rpc @@ fun myid code ->
  match%lwt Eliom_reference.get activation_code_ref with
  | Some (number, code', _) when code = code' ->
    let%lwt () = Os_db.Phone.add myid number in
    Lwt.return_true
  | _ ->
    Lwt.return_false

let%client confirm_activation_code =
  ~%(Eliom_client.server_function Deriving_Json.Json_string.t
       confirm_activation_code)

let%server connect_with_activation_code
    (firstname, lastname, code, password) =
  match%lwt Eliom_reference.get activation_code_ref with
  | Some (number, code', _) when code = code' ->
    let%lwt () = Eliom_reference.set activation_code_ref None in
    let%lwt user = Os_user.create ~password ~firstname ~lastname () in
    let userid = Os_user.userid_of_user user in
    let%lwt () = Os_db.Phone.add userid number in
    let%lwt () = Os_session.connect userid in
    Lwt.return_true
  | _ ->
    Lwt.return_false

let%client connect_with_activation_code =
  ~%(Eliom_client.server_function
       [%derive.json: string * string * string * string]
       connect_with_activation_code)

let%shared connect_with_activation_code
    ~first_name ~last_name ~code ~password () =
  connect_with_activation_code (first_name, last_name, code, password)
