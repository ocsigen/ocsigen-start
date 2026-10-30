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

(** Verification of OpenID Connect ID tokens against a known key set.

    This is the low-level part of {!Oauth}: it performs no input or output
    and takes the current time as an argument. Most applications use
    {!Oauth}, which fetches the keys of the provider and caches them. *)

val log_src : Logs.src
(** [log_src] is the log source of this module and of {!Oauth}, named
    [os:oauth]. *)

(** {1 Key sets} *)

type keys
(** The type for the public signing keys of an OpenID provider. *)

val keys_of_string : string -> (keys, string) result
(** [keys_of_string s] is the key set described by the JSON Web Key Set
    {{:https://www.rfc-editor.org/rfc/rfc7517#section-5}(RFC 7517)} [s]. Keys
    that cannot be decoded are skipped. It is [Error msg] if [s] is not a
    JSON object with a [keys] array. *)

val max_age : string -> int option
(** [max_age cache_control] is the value, in seconds, of the [max-age]
    directive of the [Cache-Control] header value [cache_control], if any. *)

(** {1 Token validation} *)

(** The type for the reasons why a token is refused. *)
type error =
  | Malformed of string
  (** The token is not a compact JSON Web Signature with a JSON header and
      payload. *)
  | Unknown_key of string
  (** The token is signed with a key id that the key set does not contain. *)
  | Rejected of string
  (** The algorithm, the signature or one of the claims is invalid. *)

val pp_error : Format.formatter -> error -> unit
(** [pp_error] formats an error for the logs. *)

val validate :
   now:float
  -> keys:keys
  -> allowed_issuers:string list
  -> allowed_audiences:string list
  -> string
  -> (Yojson.Safe.t, error) result
(** [validate ~now ~keys ~allowed_issuers ~allowed_audiences id_token] is
    [Ok claims], the payload of [id_token], if all of the following hold:
    - the token is signed with RS256 by the RSA key of [keys] named by the
      [kid] field of its header;
    - its [iss] claim is one of [allowed_issuers];
    - its [aud] claim is one of [allowed_audiences], or a non-empty array
      whose elements all belong to [allowed_audiences];
    - its [exp] claim is a number of seconds since the epoch later than
      [now].

    Issuers and audiences are compared exactly. It is [Error e] otherwise. *)
