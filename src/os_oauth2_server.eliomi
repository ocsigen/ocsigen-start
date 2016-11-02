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

open Os_oauth2_shared

exception State_not_found
exception No_such_client
exception No_such_saved_token

(* ---------------------------- *)
(* ---------- Client ---------- *)

(* A basic OAuth2.0 client is represented by an application name, a description
 * and redirect_uri. When a client is registered, credentials and an ID is
 * assigned and becomes a {registered_client}.
 *
 * IMPROVEME:
 * For the moment, the client type is the same for all OAuth2 server. However,
 * we can be interested to register several OAuth2 server (for different
 * purpose) and in this case, we are interested to list client by OAuth2 server.
 *)

type client

val client_of_str :
  application_name:string ->
  description:string ->
  redirect_uri:Ocsigen_lib.Url.t ->
  client

val application_name_of_client :
  client ->
  string

val redirect_uri_of_client :
  client ->
  Ocsigen_lib.Url.t

val description_of_client :
  client ->
  string

val client_of_id :
  Os_types.OAuth2.Client.id ->
  client Lwt.t

(* Create a new client by generating credentials. The return value is the ID in
 * the database.
 *)
val new_client                 :
  application_name:string         ->
  description:string              ->
  redirect_uri:Ocsigen_lib.Url.t  ->
  Os_types.OAuth2.Client.id Lwt.t

(** Remove the client with the id [id] from the database. *)
val remove_client_by_id :
  Os_types.OAuth2.Client.id ->
  unit Lwt.t

(** Remove the client with the client_id [client_id] from the database.
 * Client_id can be used because it must be unique. It calls
 * remove_client_by_id after getting the id *)
val remove_client_by_client_id :
  string                  ->
  unit Lwt.t

(* ---------- Client ---------- *)
(* ---------------------------- *)

(* --------------------------------------- *)
(* ---------- Registered client ---------- *)

(** A registered client contains basic information about the client, its ID
 * in the database and its credentials. It represents a client which is
 * registered in the database.
 *)
type registered_client

val id_of_registered_client          :
  registered_client  ->
  Os_types.OAuth2.Client.id

val client_of_registered_client      :
  registered_client  ->
  client

val credentials_of_registered_client :
  registered_client  ->
  client_credentials

val to_registered_client             :
  Os_types.OAuth2.Client.id ->
  client                    ->
  client_credentials        ->
  registered_client

(** Return the registered client having [client_id] as client id *)
val registered_client_of_client_id   :
  string             ->
  registered_client Lwt.t

val list_clients :
  ?min_id:Os_types.OAuth2.Client.id ->
  ?limit:Int64.t                    ->
  unit                              ->
  registered_client list Lwt.t

(* ---------- Registered client ---------- *)
(* --------------------------------------- *)

module type SCOPE =
  sig
    (** Scope is a list of permissions *)
    type scope

    val scope_of_str :
      string ->
      scope

    val scope_to_str :
      scope ->
      string

    (** check_scope_list is used to check if the scope asked by the client is
     * allowed. You can implement simple check_scope_list by only check is all
     * element of the scope list is defined but you can also have the case where
     * two scopes can't be asked at the same time.
     *)
    val check_scope_list :
      scope list ->
      bool
  end

module type TOKEN =
  sig
    type scope

    type saved_token

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

    val id_client_of_saved_token  :
      saved_token ->
      Os_types.OAuth2.Client.id

    val userid_of_saved_token     :
      saved_token ->
      Os_types.User.id

    val value_of_saved_token      :
      saved_token ->
      string

    val token_type_of_saved_token :
      saved_token ->
      string

    val scope_of_saved_token      :
      saved_token ->
      scope list

    val counter_of_saved_token    :
      saved_token ->
      int ref

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
      Os_types.OAuth2.Client.id   ->
      string                      ->
      saved_token

    (* List all saved tokens *)
    val list_tokens               :
      unit                        ->
      saved_token list

    val saved_token_to_json       :
      saved_token                 ->
      Yojson.Safe.json
  end

module type SERVER =
  sig
    (* --------------------------- *)
    (* ---------- Scope ---------- *)

    (** Scope is a list of permissions *)
    type scope

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
      scope list ->
      string list

    (* --------------------------- *)
    (* ---------- Scope ---------- *)

    (* --------------------------------------------- *)
    (* ---------- request code information --------- *)

    val set_userid_of_request_info_code :
      string ->
      string ->
      Os_types.User.id ->
      unit

    (* ---------- request code information --------- *)
    (* --------------------------------------------- *)

    (** ------------------------------------------------------------ *)
    (** ---------- Functions about the authorization code ---------- *)

    (** send_authorization_code [state] [redirect_uri] [client_id] [scope] sends
     * an authorization code to redirect_uri
     * including the state [state]. This function can be called by
     * the authorization handler. It uses Eliom_lib.change_page.
     * It avoids to know how OAuth2 works and to implement the redirection
     * manually.
     * NOTE: The example in the RFC is a redirection but it is not mentionned
     * if is mandatory. So we use change_page.
     * FIXME: They don't return a page normally. We need to change for a Any.
     *)

    val send_authorization_code :
      string                                ->
      string                                ->
      Eliom_registration.Html.page Lwt.t

    val send_authorization_code_error :
      ?error_description:string option      ->
      ?error_uri:string option              ->
      error_authorization_code_type         ->
      string                                ->
      Ocsigen_lib.Url.t                     ->
      Eliom_registration.Html.page Lwt.t

    val rpc_resource_owner_authorize  :
      (
        Deriving_Json.Json_string.a *
        Deriving_Json.Json_string.a,
        Eliom_registration.Html.page
      )
      Eliom_client.server_function

    val rpc_resource_owner_decline    :
      (
        Deriving_Json.Json_string.a * Deriving_Json.Json_string.a,
        Eliom_registration.Html.page
      )
      Eliom_client.server_function

    (** ---------- Functions about the authorization code ---------- *)
    (** ------------------------------------------------------------ *)

    (** ------------------------------------------ *)
    (** ---------- Function about token ---------- *)

    type saved_token

    val id_client_of_saved_token  : saved_token -> Os_types.OAuth2.Client.id
    val userid_of_saved_token     : saved_token -> Os_types.User.id
    val value_of_saved_token      : saved_token -> string
    val token_type_of_saved_token : saved_token -> string
    val scope_of_saved_token      : saved_token -> scope list

    val token_exists              :
      saved_token           ->
      bool

    val save_token                :
      saved_token           ->
      unit

    val remove_saved_token        :
      saved_token           ->
      unit

    val saved_token_of_id_client_and_value :
      Os_types.OAuth2.Client.id   ->
      string                      ->
      saved_token

    val list_tokens               :
      unit                  ->
      saved_token list

    (** ---------- Function about token ---------- *)
    (** ------------------------------------------ *)


    (** ---------- URL registration ---------- *)
    (** -------------------------------------- *)

    (** When registering, we need to have several get parameters so we need to
     * force the developer to have these GET parameter. We define a type for the
     * token handler and the authorization handler.
     * because they have different GET parameters.
     *
     * There are not abstract because we need to know the type. And it's also
     * known due to RFC.
     **)

    (** ------------------------------------------------ *)
    (** ---------- Authorization registration ---------- *)

    (* --------------------- *)
    (* authorization service *)

    (** Type of pre-defined service for authorization service. It's a GET
     * service
     *)
    (* NOTE: need to improve this type! It's so ugly *)
    type authorization_service =
      (string * (string * (string * (string * string))),
      unit,
      Eliom_service.get,
      Eliom_service.att,
      Eliom_service.non_co,
      Eliom_service.non_ext,
      Eliom_service.reg, [ `WithoutSuffix ],
      [ `One of string ]
      Eliom_parameter.param_name *
      ([ `One of string ]
       Eliom_parameter.param_name *
       ([ `One of string ]
        Eliom_parameter.param_name *
        ([ `One of string ]
         Eliom_parameter.param_name *
         [ `One of string ]
         Eliom_parameter.param_name))),
      unit, Eliom_service.non_ocaml)
      Eliom_service.t

    (** authorization_service [path] returns a service for the authorization URL.
     * You can use it with Your_app_name.App.register with
     * {!authorization_handler} *)
    val authorization_service :
      Eliom_lib.Url.path ->
      authorization_service

    (* authorization service *)
    (* --------------------- *)

    (* --------------------- *)
    (* authorization handler *)

    type authorization_handler  =
      state:string                        ->
      client_id:Os_types.OAuth2.client_id ->
      redirect_uri:Ocsigen_lib.Url.t      ->
      scope:scope list                    ->
      Eliom_registration.Html.page Lwt.t (* Return value of the handler *)

    (** authorize_handler [handler] returns a handler for the authorization URL.
     * You can use it with Your_app_name.App.register with
     * {!authorization_service}
     *)
    val authorization_handler :
      authorization_handler ->
      (
        (string * (string * (string * (string * string))))  ->
        unit                                                ->
        Eliom_registration.Html.page Lwt.t
      )

    (* authorization handler *)
    (* --------------------- *)

    (** ---------- Authorization registration ---------- *)
    (** ------------------------------------------------ *)

    (** ---------------------------------------- *)
    (** ---------- Token registration ---------- *)

    (* ------------- *)
    (* token service *)

    (** Type of pre-defined service for token service. It's a POST service. *)
    (* NOTE: need to improve this type! It's so ugly *)
    type token_service =
      (unit,
      string * (string * (string * (string * string))),
      Eliom_service.post,
      Eliom_service.att,
      Eliom_service.non_co,
      Eliom_service.non_ext,
      Eliom_service.reg,
      [ `WithoutSuffix ],
      unit,
      [ `One of string ] Eliom_parameter.param_name *
      ([ `One of string ] Eliom_parameter.param_name *
        ([ `One of string ] Eliom_parameter.param_name *
          ([ `One of string ] Eliom_parameter.param_name *
            [ `One of string ] Eliom_parameter.param_name))),
      Eliom_registration.String.return)
      Eliom_service.t

    (** token_service [path] returns a service for the access token URL.
     * You can use it with Your_app_name.App.register with
     * {!token_handler}
     *)
    val token_service :
      Ocsigen_lib.Url.path ->
      token_service

    (* token service *)
    (* ------------- *)

    (* ------------- *)
    (* token handler *)

    (** token_handler returns a handler for the access token URL.
     * You can use it with Your_app_name.App.register with
     * {!token_service}
     *)
    val token_handler :
      (
        unit                                                  ->
        (string * (string * (string * (string * string))))    ->
        Eliom_registration.String.result Lwt.t
      )

    (* token handler *)
    (* ------------- *)

    (** ---------- Token registration ---------- *)
    (** ---------------------------------------- *)

    (** ---------- URL registration ---------- *)
    (** -------------------------------------- *)

  end

module MakeBasicToken : functor
  (Scope : SCOPE) -> (TOKEN with type scope = Scope.scope)

module MakeServer : functor
  (Scope : SCOPE) -> functor
  (Token : (TOKEN with type scope = Scope.scope)) ->
  (SERVER with
    type scope = Scope.scope and
    type saved_token = Token.saved_token
  )

module Basic_scope : SCOPE

module Basic_token : TOKEN

module Basic : (SERVER with type scope = Basic_scope.scope)
