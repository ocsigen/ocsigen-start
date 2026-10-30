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

(** Verification of OpenID Connect ID tokens, such as the ones of "Sign in
    with Google".

    The browser obtains a signed ID token from the identity provider and
    sends it to the server, which checks it with this module before trusting
    its claims (for instance [sub], the stable user identifier, or [email]).

    The signing keys of a provider are fetched from its JSON Web Key Set
    (JWKS) URL and kept in memory for the time given by the [max-age]
    directive of the [Cache-Control] header of the response, one hour if
    there is none. They are fetched again shortly before that time, and also
    when a token names a key id that the cached set does not contain, at most
    once a minute, since the provider may have published new keys.

    This module is server-side only. It logs to the [os:oauth] source of the
    Logs library. *)

val validate_token :
   jwks_uri:Uri.t
  -> allowed_issuers:string list
  -> allowed_audiences:string list
  -> string
  -> Yojson.Safe.t option Lwt.t
(** [validate_token ~jwks_uri ~allowed_issuers ~allowed_audiences id_token] is
    [Some claims], the payload of [id_token], if:
    - the token is signed with RS256 by the key of the JWKS at [jwks_uri]
      named by the [kid] field of its header;
    - its [iss] claim is one of [allowed_issuers];
    - its [aud] claim is one of [allowed_audiences], or a non-empty array
      whose elements all belong to [allowed_audiences];
    - its [exp] claim is in the future.

    Issuers and audiences are compared exactly. It is [None] if one of these
    checks fails, the reason being logged at the info level, or if the key
    set cannot be fetched, which is logged at the error level.

    [allowed_audiences] usually contains the client ids of the application.
    See {!Core_oauth.validate} to check a token against keys obtained
    otherwise. *)

(** "Sign in with Google". *)
module Google : sig
  val jwks_uri : Uri.t
  (** [jwks_uri] is the URL of Google's JWKS,
      [https://www.googleapis.com/oauth2/v3/certs]. *)

  val issuers : string list
  (** [issuers] are the two issuers of Google's ID tokens,
      [accounts.google.com] and [https://accounts.google.com]. *)

  val validate : client_ids:string list -> string -> Yojson.Safe.t option Lwt.t
  (** [validate ~client_ids id_token] is
      [validate_token ~jwks_uri ~allowed_issuers:issuers
      ~allowed_audiences:client_ids id_token]. [client_ids] are the OAuth
      client ids of the application in the Google Cloud console. *)
end
