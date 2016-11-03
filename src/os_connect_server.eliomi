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
    ({!Basic_ID_Token}) and client implementation ({!Basic}).
 *)

(** Exception raised when the given token doesn't exist. *)
exception No_such_saved_token

module type IDTOKEN =
  sig
    type scope

    type saved_token

    val saved_tokens : saved_token list ref

    val cycle_duration  : int

    val number_of_cycle : int

    val id_client_of_saved_token :
      saved_token ->
      Os_types.OAuth2.Client.id

    val userid_of_saved_token :
      saved_token ->
      Os_types.User.id

    val token_type_of_saved_token :
      saved_token ->
      string

    val value_of_saved_token :
      saved_token ->
      string

    val id_token_of_saved_token :
      saved_token ->
      Jwt.t

    val scope_of_saved_token :
      saved_token ->
      scope list

    val secret_key_of_saved_token :
      saved_token ->
      string

    val counter_of_saved_token    :
      saved_token ->
      int ref

    (* getters *)
    (* ------- *)

    (* Returns true if the token already exists *)
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

    (* Save a token *)
    val save_token                :
      saved_token                 ->
      unit

    val remove_saved_token        :
      saved_token                 ->
      unit

    val saved_token_of_id_client_and_value :
      Os_types.OAuth2.Server.id ->
      string                    ->
      saved_token

    (* List all saved tokens *)
    val list_tokens               :
      unit                        ->
      saved_token list

    val saved_token_to_json       :
      saved_token                 ->
      Yojson.Safe.json
  end

(** Basic module for scopes.
    [check_scope_list scope_list] returns [true] if every element in
    [scope_list] is an available scope value.
    If the list contains only [OpenID] or if the list doesn't contain [OpenID]
    (mandatory scope in RFC), returns [false].
    If an unknown scope value is in list (represented by [Unknown] value),
     returns [false].
 *)

module Basic_scope : Os_oauth2_server.SCOPE

module MakeIDToken : functor
  (Scope : Os_oauth2_server.SCOPE) ->
  (IDTOKEN with type scope = Scope.scope)

module Basic_ID_token
  : (IDTOKEN with
    type scope = Basic_scope.scope)

module Basic : (Os_oauth2_server.SERVER with
  type scope = Basic_scope.scope and
  type saved_token = Basic_ID_token.saved_token
)
