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

(** OAuth2.0 client with default scopes ({!Basic_scope}), Tokens
    ({!Basic_token}) and client implementation ({!Basic}).
 *)

open Os_oauth2_shared

(* ---------- Exceptions ---------- *)
(** {1 Exceptions } *)

(** Raised if a state is not found. *)
exception State_not_found

(** Raised if no such client has been found. *)
exception No_such_client

(** Raised if the given server ID already exists. *)
exception Server_id_exists

(** Raised if a bad server ID has been given. *)
exception No_such_server

(** Exception raised when the given token doesn't exist. *)
exception No_such_saved_token

(** Exception raised when the JSON received from the OpenID Connect server is
    not well formated or if there is missing fields.
 *)
exception Bad_JSON_respoonse

(** {2 About OAuth2.0 servers and client credentials. } *)

(** The type representing a registered server.
    A registered server is a server saved in the database with:
    - an ID.
    - a server ID which is a string to recognize the OAuth2.0 server easily
      (instead of using the ID).
    - an authorization URL which must be used to get an authorization code.
    - a token URL which must be used to get a token when an authorization code
      has been delivered by the authorization server.
    - a data URL which must be used to get the data.
    - the client credentials (client ID and client secret) which must be used to
      be recognized by the server.
 *)
type registered_server

(** Get the ID database. *)
val id_of_registered_server                 :
  registered_server                       ->
  int64

(** Get the server ID which is a string to recognize it easily. *)
val server_id_of_registered_server          :
  registered_server                       ->
  string

(** Get the authorization URL which must be used to get an authorization
    code.
 *)
val authorization_url_of_registered_server  :
  registered_server                       ->
  string

(** Get the token URL which must be used to get a token after requesting an
    authorization code.
 *)
val token_url_of_registered_server          :
  registered_server                       ->
  string

(** Get the data URL which must be used to get the data. *)
val data_url_of_registered_server           :
  registered_server                       ->
  string

(** Get the client credentials. *)
val client_credentials_of_registered_server :
  registered_server                       ->
  client_credentials

(** Build a type {!registered_server}. *)
val to_registered_server                    :
  id:int64                                ->
  server_id:string                        ->
  authorization_url:string                ->
  token_url:string                        ->
  data_url:string                         ->
  client_credentials:client_credentials   ->
  registered_server

(** List all registered servers. Data are retrieved from the database. *)
val list_servers        :
  unit                ->
  registered_server list Lwt.t

(** Save a new server in the database.
    If an OAuth2.0 is already registered with [server_id] exists, the exception
    {!Server_id_exists} is raised.
 *)
val save_server :
  server_id:string                  ->
  server_authorization_url:string   ->
  server_token_url:string           ->
  server_data_url:string            ->
  client_id:string                  ->
  client_secret:string              ->
  unit Lwt.t

(** [remove_server_by_id id] removes from the database the registered server
    with ID [id].
 *)
val remove_server_by_id :
  int64                             ->
  unit Lwt.t

(** Get the client credientials for a given OAuth2.0 server. *)
val get_client_credentials : server_id:string -> client_credentials Lwt.t

(** {3 About scopes, tokens and basic client. } *)

(** Module type for scopes. *)

module type SCOPE = sig
  (** Available scopes. *)
  type scope

  (** Default scopes set in all requests where scope is needed. *)
  val default_scopes : scope list

  val scope_of_str :
    string ->
    scope

  val scope_to_str :
    scope ->
    string
end

(** Module type for tokens. Represents tokens used by the OAuth2.0 server. *)

module type TOKEN = sig

  (** Represents a saved token. The type is abstract to let the choice of the
      implementation.
      A token must contain at least:
      - the OAuth2.0 server ID to know which server delivers the token.
        The ID is related to the database.
      - a value. It's the token value.
      - the token type. For example ["bearer"].
      - the ID token as a JSON Web Token (JWT).
      - a counter which represents the number of times the token has been
        checked by the timer.
   *)
  type saved_token

  (** Represents the list of all saved tokens. *)
  val saved_tokens : saved_token list ref

  (** Tokens must expire after a certain amount of time. For this reason, a
      timer {!Os_oauth2_shared.update_list_timer} checks all {!cycle_duration}
      seconds if the token has been generated after {!cycle_duration} *
      {!number_of_cycle} seconds. If it's the case, the token is removed.
   *)
  (** The duration of a cycle. *)
  val cycle_duration : int

  (** [number_of_cycle] the number of cycle. *)
  val number_of_cycle : int

  (** Returns the OpenID Connect server ID which delivered the token. *)
  val id_server_of_saved_token :
    saved_token ->
    int64

  (** Returns the token value. *)
  val value_of_saved_token                 :
    saved_token ->
    string

  (** Returns the token type (for example ["bearer"]. *)
  val token_type_of_saved_token            :
    saved_token ->
    string

  (** Returns the number of remaining cycles. *)
  val counter_of_saved_token               :
    saved_token  ->
    int ref

  (** [parse_json_token id_server token] parse the JSON data returned by the
      token server (which has the ID [id_server] in the database) and returns
      the corresponding {!save_token} OCaml type. The
      Must raise {!Bad_JSON_response} if all needed information are not given.
      Unrecognized JSON attributes must be ignored.
   *)
  val parse_json_token    :
    int64                ->
    Yojson.Basic.json    ->
    saved_token

  (** [saved_token_of_id_server_and_value id_server value] returns the
      saved_token delivered by the server with ID [id_server] and with value
     [value].
     Raise an exception {!No_such_saved_token} if no token has been delivered by
     [id_server] with value [value].

     It implies OpenID Connect servers delivers unique token values, which is
     logical for security.
   *)
  val saved_token_of_id_server_and_value   :
    int64               ->
    string              ->
    saved_token

  (** [save_token token] saves a new token. *)
  val save_token          :
    saved_token         ->
    unit

  (** Returns all saved tokens as a list. *)
  val list_tokens         :
    unit                ->
    saved_token list

  (** [remove_saved_token token] removes [token] (used for example when [token]
      is expired.
   *)
  val remove_saved_token  :
    saved_token         ->
    unit
  end

(** Module type representing a OAuth2.0 client. *)

module type CLIENT = sig
  (** The following types and functions related to tokens and scopes are
      aliases to the same types and functions from the module type given in the
      functor {!MakeClient}. These aliases avoid to know the modules used to
      build the client.
   *)

  type scope

  val default_scopes : scope list

  val scope_of_str :
    string ->
    scope

  val scope_to_str :
    scope ->
    string

  val scope_list_of_str_list :
    string list ->
    scope list

  val scope_list_to_str_list :
    scope list  ->
    string list

  type saved_token

  val id_server_of_saved_token    : saved_token -> int64
  val value_of_saved_token        : saved_token -> string
  val token_type_of_saved_token   : saved_token -> string

  val saved_token_of_id_server_and_value :
    int64               ->
    string              ->
    saved_token

  val list_tokens         :
    unit                ->
    saved_token list

  val remove_saved_token  :
    saved_token         ->
    unit

  (** When registering, clients must specify a redirect uri where the code will
     be sent as GET parameter (or the authorization code error).
     [register_redirect_uri ~redirect_uri ~success_redirection ~error_rediction]
     registers two services at the url [redirect_uri] :
     - for successfull authorization code response.
     - for error authorization code response.

     In the case of a successfull authorization code, this service will
     request an access token to the token server and if the token server
     responds with success, the token is saved in the database and a
     redirection is done to the service [success_redirection].

     In the case of an error response (while requesting an authorization code
     or a token), we redirect the user to the service [error_redirection].

   *)

  val register_redirect_uri :
    redirect_uri:string ->
    success_redirection:
      Eliom_service.non_ocaml Eliom_registration.Redirection.page ->
    error_redirection:
      Eliom_service.non_ocaml Eliom_registration.Redirection.page ->
    unit Lwt.t

  (**
     [request_authorization_code
      ~redirect_uri ~server_id ~scope=["firstname", "lastname"]
     ]
     requests an authorization code to the OAuth2 server represented by
     [~server_id] to get access to the firstname and lastname of the resource
     owner. [~server_id] is needed to get credentials. [~redirect_uri] is used
     to redirect the user-agent on the client OAuth2.

     You will never manipulate the authorization code. The code is temporarily
     saved server side until expiration in the HTTP parameter.
     The next time you request an access token, authorization code will
     be checked and if it's not expired, request an access token to the
     OAuth2.0 server.

     The default scopes {!SCOPE.default_scopes} are set in addition to [~scope].

     An exception {!No_such_server} is raised if no server is registered with
     [server_id].
   *)
  val request_authorization_code :
    redirect_uri:string   ->
    server_id:string      ->
    scope:scope list ->
    unit Lwt.t

end

(** Basic_scope is a {!SCOPE} module representing a basic scope list (firstname,
    lastname and email).
    This scope representation is used in {!Os_oauth2_server.Basic} so you can to
    use this module if the OAuth2.0 server is an instance of
    {!Os_oauth2_server.Basic}.

    See {!Os_oauth2_client.Basic} for a basic OAuth2 client compatible with
    the OAuth2 server {!Os_oauth2_server.Basic}.
 *)
module Basic_scope : sig
    type scope = OAuth | Firstname | Lastname | Email | Unknown

    val scope_of_str :
      string ->
      scope

    val scope_to_str :
      scope ->
      string
  end

(** Basic_token is a {!TOKEN} module representing a basic token (id_server,
    value and token_type.
    This token representation is used in {!Os_oauth2_server.Basic} so you can to
    use this module if the OAuth2 server is an instance of
    {!Os_oauth2_server.Basic}.

    See {!Os_oauth2_client.Basic} for a basic OAuth2 client compatible with
    the OAuth2 server {!Os_oauth2_server.Basic}.
 *)
module Basic_token : TOKEN

(** Build a OAuth2 client from a module of type {!SCOPE} and a module of type
    {!TOKEN}. In this way, you have a personalized OAuth2.0 client.
 *)
module MakeClient : functor
  (Scope : SCOPE) -> functor
  (Token : TOKEN) ->
  (CLIENT with
    type scope = Scope.scope and
    type saved_token = Token.saved_token
  )

(** Basic OAuth2 client, compatible with OAuth2.0 server
    {!Os_oauth2_server.Basic}.
 *)
module Basic : (CLIENT with type scope = Basic_scope.scope and type saved_token
= Basic_token.saved_token)
