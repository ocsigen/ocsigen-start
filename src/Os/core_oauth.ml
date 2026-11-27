(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright (C) Be Sport, Tarides.
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

let log_src = Logs.Src.create "os:oauth"

type keys = Jose.Jwks.t

let parse_key json =
  match Jose.Jwk.of_pub_json json with
  | Ok key -> Some key
  | Error (`Json_parse_failed msg | `Msg msg) ->
      Logs.debug ~src:log_src (fun m -> m "Skipping a key: %s" msg);
      None
  | Error `Unsupported_kty ->
      Logs.debug ~src:log_src (fun m -> m "Skipping a key of unsupported type");
      None
  (* [Jose.Jwk.of_pub_json] raises it when the key has no "kty" field. *)
  | exception Yojson.Safe.Util.Type_error (msg, _) ->
      Logs.debug ~src:log_src (fun m -> m "Skipping a key: %s" msg);
      None

let keys_of_string s =
  match Yojson.Safe.from_string s with
  | exception Yojson.Json_error msg -> Error msg
  | `Assoc fields -> (
    match List.assoc_opt "keys" fields with
    | Some (`List keys) -> Ok {Jose.Jwks.keys = List.filter_map parse_key keys}
    | _ -> Error "no \"keys\" array")
  | _ -> Error "not a JSON object"

let is_digit = function '0' .. '9' -> true | _ -> false

let max_age cache_control =
  String.split_on_char ',' cache_control
  |> List.find_map (fun directive ->
    match String.split_on_char '=' directive with
    | [name; value] ->
        let value = String.trim value in
        if
          String.lowercase_ascii (String.trim name) = "max-age"
          && value <> ""
          && String.for_all is_digit value
        then int_of_string_opt value
        else None
    | _ -> None)

type error = Malformed of string | Unknown_key of string | Rejected of string

let pp_error ppf = function
  | Malformed msg -> Format.fprintf ppf "malformed token: %s" msg
  | Unknown_key kid -> Format.fprintf ppf "unknown key id %S" kid
  | Rejected msg -> Format.fprintf ppf "%s" msg

let ( let* ) = Result.bind

(* Only the compact serialization is used for ID tokens. [Jose] would also
   accept the JSON ones. *)
let parse token =
  match String.split_on_char '.' token with
  | [_; _; _] -> (
    match Jose.Jwt.unsafe_of_string token with
    | Ok jwt -> Ok jwt
    | Error (`Msg msg) -> Error (Malformed msg)
    | Error `Not_json -> Error (Malformed "not JSON")
    | Error `Not_supported -> Error (Malformed "unsupported serialization")
    (* Raised by [Jose] when the payload is not JSON. *)
    | exception Yojson.Json_error msg -> Error (Malformed msg))
  | _ -> Error (Malformed "not three dot-separated segments")

(* [Jose.Jwt.validate_signature] picks the verification method from the key,
   whatever algorithm the header names, so the algorithm and the type of the
   key are both checked here first. *)
let check_signature keys jwt =
  let {Jose.Jwt.header = {Jose.Header.alg; kid; _}; _} = jwt in
  match alg with
  | `RS256 -> (
    match kid with
    | None -> Error (Malformed "no key id")
    | Some kid -> (
      match Jose.Jwks.find_key keys kid with
      | None -> Error (Unknown_key kid)
      | Some (Jose.Jwk.Rsa_pub _ as jwk) -> (
        match Jose.Jwt.validate_signature ~jwk jwt with
        | Ok jwt -> Ok jwt
        | Error `Invalid_signature -> Error (Rejected "invalid signature")
        | Error (`Msg msg) -> Error (Rejected ("invalid signature: " ^ msg)))
      | Some _ -> Error (Rejected (Printf.sprintf "key %S is not RSA" kid))))
  | alg ->
      Error (Rejected ("unsupported algorithm " ^ Jose.Jwa.alg_to_string alg))

let seconds = function
  | `Int n -> Some (Float.of_int n)
  | `Float f -> Some f
  | `Intlit s -> float_of_string_opt s
  | _ -> None

(* [Jose.Jwt.check_expiration] accepts a token without an [exp] claim, or
   whose [exp] is not an integer, so the expiry is checked here. *)
let check_claims ~now ~allowed_issuers ~allowed_audiences claims =
  let claim name =
    match claims with `Assoc fields -> List.assoc_opt name fields | _ -> None
  in
  let* () =
    match claim "iss" with
    | Some (`String iss) when List.mem iss allowed_issuers -> Ok ()
    | Some (`String iss) ->
        Error (Rejected (Printf.sprintf "issuer %S not allowed" iss))
    | _ -> Error (Rejected "no issuer")
  in
  let allowed = function
    | `String aud -> List.mem aud allowed_audiences
    | _ -> false
  in
  let* () =
    match claim "aud" with
    | Some aud when allowed aud -> Ok ()
    | Some (`List (_ :: _ as auds)) when List.for_all allowed auds -> Ok ()
    | Some _ -> Error (Rejected "audience not allowed")
    | None -> Error (Rejected "no audience")
  in
  match Option.bind (claim "exp") seconds with
  | Some exp when now < exp -> Ok ()
  | Some _ -> Error (Rejected "expired")
  | None -> Error (Rejected "no expiry")

let validate ~now ~keys ~allowed_issuers ~allowed_audiences id_token =
  let* jwt = parse id_token in
  let* jwt = check_signature keys jwt in
  let* () =
    check_claims ~now ~allowed_issuers ~allowed_audiences jwt.Jose.Jwt.payload
  in
  Ok jwt.Jose.Jwt.payload
