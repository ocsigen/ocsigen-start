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

(** OpenID Connect server with default scopes ({!Basic_scope}), ID Tokens
    ({!Basic_ID_Token}) and server implementation ({!Basic}).
 *)

(** {1 Exceptions. } *)

(** Exception raised when the given token doesn't exist. *)
exception No_such_saved_token

(** {2 Token representation. } *)

(** Token interface used by the OpenID Connect server. *)

module type IDTOKEN = sig
  (** List of permissions. Used to type the [scope] field in {!saved_token} *)
  type scope

  (** Token representation. The type is abstract to let the choice of the
      implementation.
      A token must contain at least:
      - the userid to know which user authorized.
      - the OAuth2.0 client ID to know the client to which the token is
        assigned. The ID is related to the database.
      - a value (the token value).
      - the token type (for example ["bearer"]).
      - the scopes list (of type {!scope}). Used to know which data the data
      service must send.
      - the ID token as a JSON Web Token (JWT).
      - the secret key used to sign the JWT. It is useful to check if the
      client sent the right ID token. This is the key used by HS256 to sign
      the token.
      - a counter which represents the number of times the token has been
        checked by the timer.
   *)
  type saved_token

  (** The list of all saved tokens. *)
  val saved_tokens : saved_token list ref

  (** Tokens must expire after a certain amount of time. For this reason, a
      timer {!Os_oauth2_shared.update_list_timer} checks all {!cycle_duration}
      seconds if the token has been generated after {!cycle_duration} *
      {!number_of_cycle} seconds. If it's the case, the token is removed.
   *)

  (** The duration of a cycle. *)
  val cycle_duration  : int

  (** The number of cycle. *)
  val number_of_cycle : int

  (** Return the client ID. *)
  val id_client_of_saved_token :
    saved_token ->
    Os_types.OAuth2.Client.id

  (** Return the userid of the user who authorized. *)
  val userid_of_saved_token :
    saved_token ->
    Os_types.User.id

  (** Return the token type. *)
  val token_type_of_saved_token :
    saved_token ->
    string

  (** Return the token value. *)
  val value_of_saved_token :
    saved_token ->
    string

  (** Return the ID token as a JWT. *)
  val id_token_of_saved_token :
    saved_token ->
    Jwt.t

  (** Return the scope asked by the client. *)
  val scope_of_saved_token :
    saved_token ->
    scope list

  (** Return the secret key used to sign the JWT. *)
  val secret_key_of_saved_token :
    saved_token ->
    string

  (** Return the number of passed cycle. *)
  val counter_of_saved_token    :
    saved_token ->
    int ref

  (** Return [true] if the token already exists *)
  val token_exists              :
    saved_token                 ->
    bool

  (* Generate a token value *)
  val generate_token_value      :
    unit                        ->
    string

  (* Generate a new token *)
  val generate_token            :
    id_client:Os_types.OAuth2.Client.id ->
    userid:Os_types.User.id             ->
    scope:scope list                    ->
    saved_token Lwt.t

  (** Save a token *)
  val save_token                :
    saved_token                 ->
    unit

  (** Remove a token. *)
  val remove_saved_token        :
    saved_token                 ->
    unit

  (** Return the saved token assigned to the client with given ID and
      value.
   *)
  val saved_token_of_id_client_and_value :
    Os_types.OAuth2.Server.id ->
    string                    ->
    saved_token

  (* List all saved tokens *)
  val list_tokens               :
    unit                        ->
    saved_token list

  (** Return the saved token as a JSON. Used to send to the client. *)
  val saved_token_to_json       :
    saved_token                 ->
    Yojson.Safe.json
end

(** Basic module for scopes.

    [check_scope_list scope_list] returns [true] if every element in
    [scope_list] is an available scope value.
    If the list contains only [OpenID] or if the list doesn't contain [OpenID]
    (mandatory scope in RFC), it returns [false].
    If an unknown scope value is in list (represented by [Unknown] value),
    it returns [false].
 *)

(** Basic scope *)
module Basic_scope : Os_oauth2_server.SCOPE

(** MakeIDToken (Scope) returns a module of type {!IDTOKEN} with the type
    {!IDTOKEN.scope} equals to {!Scope.scope}.

    Tokens are represented as a record with exactly the same fields available in
    the inferface {!IDTOKEN}.

    The token type is always ["bearer"].

    The related JSON contains the fields:
    - ["token_type"] with value ["bearer"].
    - ["token"] with the token value.
    - ["expires_in"] with the value [cycle_duration * number_of_cycle] i.e. 600
    seconds.
    - ["id_token"] with the JWT.


    NOTE: If you want to implement another type of tokens, you need to implement
    another functor (with the [Scope.scope] type dependency) which returns a
    module of type {!IDTOKEN}. The resulting module can be given as parameter to
    the function {!Os_oauth2_server.MakeServer}.
 *)
module MakeIDToken : functor
  (Scope : Os_oauth2_server.SCOPE) ->
  (IDTOKEN with type scope = Scope.scope)

(** Basic ID Token based on the scope from {!Basic_scope}. *)
module Basic_ID_token
  : (IDTOKEN with
    type scope = Basic_scope.scope)

(** [Basic (Scope) (Token)] returns a module representing a OpenID Connect
    server. The available scopes come from {!Scope.scope} and the token related
    functions, types and representation come from {!Token}.

    As an OpenID Connect server is based on an OAuth2.0, the server is generated
    with {!Os_oauth2_server.MakeServer}.
 *)
module Basic : (Os_oauth2_server.SERVER with
  type scope = Basic_scope.scope and
  type saved_token = Basic_ID_token.saved_token
)
