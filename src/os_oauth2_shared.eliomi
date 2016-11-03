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

(** Shared types, functions and values between the OAuth2.0/OpenID Connect
    client and server.
 *)

(** {1 Constants} *)

(** Length of state. *)
val size_state              : int

(** Length of client ID. *)
val size_client_id          : int

(** Length of client secret. *)
val size_client_secret      : int

(** Length of token. *)
val size_token              : int

(** Length of authorization code. *)
val size_authorization_code : int

(** {2 About client credentials} *)

(** Client credentials type. *)
type client_credentials

val client_credentials_of_string :
  client_id:Os_types.OAuth2.client_id         ->
  client_secret:Os_types.OAuth2.client_secret ->
  client_credentials

val client_id_of_client_credentials :
  client_credentials ->
  Os_types.OAuth2.client_id

val client_secret_of_client_credentials :
  client_credentials ->
  Os_types.OAuth2.client_secret

(** {3 Error types for authorization code. } *)

type error_authorization_code_type =
  | Auth_invalid_request
  | Auth_unauthorized_client
  | Auth_access_denied
  | Auth_unsupported_response_type
  | Auth_invalid_scope
  | Auth_server_error
  | Auth_temporarily_unavailable

val error_authorization_code_type_to_str  :
  error_authorization_code_type     ->
  string

(** {4 Error types for token. } *)

type error_token_type =
  | Token_invalid_request
  | Token_unauthorized_client
  | Token_invalid_client
  | Token_invalid_grant
  | Token_unsupported_grant_type
  | Token_invalid_scope

val error_token_type_to_str               :
  error_token_type                  ->
  string

(** {5 Parameters types for the different services. } *)

(** Parameters for the authorization service. This service must be registered on
    the server.

    The parameters are (in order):
    - the response type. For the moment, only the value ["code"] is
      supported.
    - the client ID.
    - the redirect URI.
    - the scope as a space separated list.
    - the state.
 *)
val param_authorization_code :
  (
    Eliom_service.get,
    string *
      (Os_types.OAuth2.client_id * (Ocsigen_lib.Url.t * (string * string))),
    [ `One of string ] Eliom_parameter.param_name *
    ([ `One of Os_types.OAuth2.client_id ] Eliom_parameter.param_name *
     ([ `One of Ocsigen_lib.Url.t ] Eliom_parameter.param_name *
      ([ `One of string ] Eliom_parameter.param_name *
       [ `One of string ] Eliom_parameter.param_name))),
    unit,
    unit,
    [ `WithoutSuffix ],
    unit
  )
  Eliom_service.meth

(** Parameters for the authorization code response service. This service must be
    registered on the client and use by the server to send the code in case
    of success.

    The parameters are (in order):
    - the code.
    - the state.
 *)
val param_authorization_code_response :
  (
    Eliom_service.get,
    string * string,
    [ `One of string ] Eliom_parameter.param_name *
      [ `One of string ] Eliom_parameter.param_name,
    unit,
    unit,
    [ `WithoutSuffix ],
    unit
  )
  Eliom_service.meth

(** Parameters for the authorization code response service. This service must be
    registered on the client and use by the server to send the response in case
    of error.

    The parameters are (in order):
    - the error.
    - an (optional) error description
    - an (optional) error URI to describe the error.
    - the state.
 *)
val param_authorization_code_response_error :
  (
    Eliom_service.get,
    string * (string option * (Ocsigen_lib.Url.t option * string)),
    [ `One of string ] Eliom_parameter.param_name *
    ([ `One of string ] Eliom_parameter.param_name *
     ([ `One of Ocsigen_lib.Url.t ] Eliom_parameter.param_name *
      [ `One of string ] Eliom_parameter.param_name)),
    unit,
    unit,
    [ `WithoutSuffix ],
    unit
  )
  Eliom_service.meth

(** Parameters for the token service. This service must be registered on the
    server.

    The parameters are (in order):
    - the grant type. For the moment, only the value ["authorization_code"] is
    supported.
    - the code.
    - the redirect URI.
    - the state.
    - the client ID.
 *)
val param_access_token :
  (
    Eliom_service.post,
    unit,
    unit,
    string *
      (string * (Ocsigen_lib.Url.t * (string * Os_types.OAuth2.client_id))),
    [ `One of string ] Eliom_parameter.param_name *
    ([ `One of Ocsigen_lib.Url.t ] Eliom_parameter.param_name *
     ([ `One of string ] Eliom_parameter.param_name *
      ([ `One of string ] Eliom_parameter.param_name *
       [ `One of Os_types.OAuth2.client_id ] Eliom_parameter.param_name))),
    [ `WithoutSuffix ],
    unit
  )
  Eliom_service.meth

(** {6 MISC functions. } *)

(** [update_list_timer seconds fn_check fn_timeout list] creates a Lwt timeout
    each [seconds] (see <<a_api project="lwt" | Lwt_timeout.create>> and <<a_api
    project="lwt" | Lwt_timeout.start>>). After this timeout, [fn_timeout] is
    executed on each element of [list] for which [fn_check] is [true].

    This function is used to remove saved tokens when they are expired.
 *)
val update_list_timer :
  int ->
  ('a -> bool) ->
  ('a -> unit) ->
  'a list ref ->
  unit    ->
  unit

(** [generate_random_string length] generates an alphanumeric string of length
    [length].
 *)
val generate_random_string :
  int  ->
  string

(** [prefix_and_path_of_t url] splits [url] in a couple [(prefix, path)] where
    [prefix] is ["http(s)://host:port"] and [path] is the path as [string list]

    Example: [prefix_and_path_of_t "http://ocsigen.org:80/tuto/manual"]
    returns [("http://ocsigen.org:80", ["tuto", "manual"])].
 *)
val prefix_and_path_of_url :
  Ocsigen_lib.Url.t ->
  string * string list
