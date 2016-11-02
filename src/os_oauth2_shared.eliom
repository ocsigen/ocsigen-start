(* Ocsigen-start
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

open Eliom_parameter
open Lwt.Infix

exception No_such_client
exception Server_id_exists
exception Empty_content

(* Put these variable in Makefile? *)
let size_authorization_code         = 42
let size_client_id                  = 42
let size_client_secret              = 42
let size_token                      = 42
let size_state                      = 42

(* Expiration time for the authorization code: default 10 minutes *)
let expiration_time_authorization_code = 10 * 60

(* -------------------------------------------------------------------------- *)
(** Shared types definitions between the OAuth2.0 client and server *)

(** -------------------------- *)
(** Type of client credentials *)

type client_credentials =
  {
    client_id     : string ;
    client_secret : string
  }

let client_credentials_of_str ~client_id ~client_secret =
  {
    client_id;
    client_secret
  }

let client_credentials_id c     = c.client_id
let client_credentials_secret c = c.client_secret

(** -------------------------- *)

(** ---------------------------------- *)
(** Error types for authorization code *)

type error_authorization_code_type =
  | Auth_invalid_request
  | Auth_unauthorized_client
  | Auth_access_denied
  | Auth_unsupported_response_type
  | Auth_invalid_scope
  | Auth_server_error
  | Auth_temporarily_unavailable

let error_authorization_code_type_to_str e = match e with
  | Auth_invalid_request           -> "invalid_request"
  | Auth_unauthorized_client       -> "unauthorized_client"
  | Auth_access_denied             -> "access_denied"
  | Auth_unsupported_response_type -> "unsupported_response_type"
  | Auth_invalid_scope             -> "invalid_scope"
  | Auth_server_error              -> "server_error"
  | Auth_temporarily_unavailable   -> "temporarily_unavailable"

(** Error types for authorization code *)
(** ---------------------------------- *)

(** --------------------- *)
(** Error types for token *)

type error_token_type =
  | Token_invalid_request
  | Token_unauthorized_client
  | Token_invalid_client
  | Token_invalid_grant
  | Token_unsupported_grant_type
  | Token_invalid_scope

let error_token_type_to_str e = match e with
  | Token_invalid_request           -> "invalid_request"
  | Token_unauthorized_client       -> "unauthorized_client"
  | Token_unsupported_grant_type    -> "unsupported_grant_type"
  | Token_invalid_client            -> "invalid_client"
  | Token_invalid_grant             -> "invalid_grant"
  | Token_invalid_scope             -> "invalid_scope"

(** Error types for token *)
(** --------------------- *)


(** ------------------------------------------- *)
(** Parameters types for the different services *)

let param_authorization_code = Eliom_service.Get
  (
    (Eliom_parameter.string "response_type") **
    ((Eliom_parameter.string "client_id") **
      ((Eliom_parameter.string "redirect_uri") **
        ((Eliom_parameter.string "scope") **
          (Eliom_parameter.string "state")
        )
      )
    )
  )

let param_authorization_code_response = Eliom_service.Get
  (
    (Eliom_parameter.string "code") **
    (Eliom_parameter.string "state")
  )

let param_authorization_code_response_error = Eliom_service.Get
  (
    (Eliom_parameter.string "error") **
    ((Eliom_parameter.opt (Eliom_parameter.string "error_description")) **
      ((Eliom_parameter.opt (Eliom_parameter.string "error_uri")) **
        ((Eliom_parameter.string "state"))
      )
    )
  )

let param_access_token = Eliom_service.Post
  (Eliom_parameter.unit,
    ((Eliom_parameter.string "grant_type") **
      ((Eliom_parameter.string "code") **
        ((Eliom_parameter.string "redirect_uri") **
          ((Eliom_parameter.string "state") **
            (Eliom_parameter.string "client_id")
          )
        )
      )
    )
  )
(** Parameters types for the different services *)
(** ------------------------------------------- *)

(* -------------------------------------------------------------------------- *)

let remove_from_list f l =
  let rec local l buf =
    match l with
  | [] -> List.rev buf
  | head::tail ->
      if f head
      then (List.rev buf) @ tail
      else local tail (head::buf)
  in
  local l []

let rec update_list_timer timer fn_remove fn_incr l () =
  let rec locale l = match l with
  | [] -> []
  | head :: tail ->
      (* if the token is expired we remove it by going to the next *)
      if fn_remove head
      then (locale tail)
      (* else, all next one aren't expired (FIFO) so we return the tail *)
      else tail
  in
  l := locale !l;
  List.iter fn_incr (!l);
  Lwt_timeout.start
    (Lwt_timeout.create timer (update_list_timer timer fn_remove fn_incr l))

(** Generate a random string with alphanumerical values (capitals or not) with a
    given [length].
 *)
let generate_random_string length =
  let random_character () = match Random.int (26 + 26 + 10) with
    n when n < 26 -> int_of_char 'a' + n
  | n when n < 26 + 26 -> int_of_char 'A' + n - 26
  | n -> int_of_char '0' + n - 26 - 26 in
  let random_character _ = String.make 1 (char_of_int (random_character ())) in
  String.concat "" (Array.to_list (Array.init length random_character))

(** [base_and_path_of_url "http://ocsigen.org:80/tuto/manual"] returns
    (base, path) where base is "http://ocsigen.org:80" and path is
    ["tuto", "manual"]
 *)
let prefix_and_path_of_url url =
  let (https, host, port, _, path, _, _) = Ocsigen_lib.Url.parse url in
  let https_str = match https with
  | None -> ""
  | Some x -> if x then "https://" else "http://"
  in
  let host_str = match host with
  | None -> ""
  | Some x -> x
  in
  let port_str = match port with
  | None -> ""
  | Some x -> string_of_int x
  in
  (https_str ^ host_str ^ ":" ^ port_str, path)
