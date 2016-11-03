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

(** OAuth2.0 server with default scopes ({!Basic_scope}), Tokens
    ({!Basic_token}) and server implementation ({!Basic}).
 *)

(** Raised when a state is not found. *)
exception State_not_found

(** Raised when the given client doesn't exist. *)
exception No_such_client

(** Raised when the given saved token doesn't exist. *)
exception No_such_saved_token

(** {1 Clients. } *)

(**
   A basic OAuth2.0 client is represented by an application name, a description
   and redirect_uri. When a client is registered, credentials and an ID is
   assigned and becomes a {registered_client}.

   IMPROVEME:
   For the moment, the client type is the same for all OAuth2 server. However,
   it can be interesting to register several OAuth2 servers (for different
   purpose) and in this case, we are interested to list client by OAuth2 server.
 *)

type client

(** Get a type {!client} *)
val client_of_string :
  application_name:string ->
  description:string ->
  redirect_uri:Ocsigen_lib.Url.t ->
  client

(** Get the application name of the client. *)
val application_name_of_client :
  client ->
  string

(** Get the redirect URI of the client. *)
val redirect_uri_of_client :
  client ->
  Ocsigen_lib.Url.t

(** Get the client description. *)
val description_of_client :
  client ->
  string

(** [client_of_id id] returns the client with id [id] as a {!client} type. Data
     are retrieved from the database.
 *)
val client_of_id :
  Os_types.OAuth2.Client.id ->
  client Lwt.t

(** Create a new client by generating credentials (client ID and client secret).
    The return value is the ID in the database.
 *)
val new_client                 :
  application_name:string         ->
  description:string              ->
  redirect_uri:Ocsigen_lib.Url.t  ->
  Os_types.OAuth2.Client.id Lwt.t

(** [remove_client_by_id id] removes the client with id [id] from the
    database.
 *)
val remove_client_by_id :
  Os_types.OAuth2.Client.id ->
  unit Lwt.t

(** [remove_client_by_client_id client_id] removes the client with the client_id
    [client_id] from the database.
    The client ID can be used because it must be unique.
 *)
val remove_client_by_client_id :
  string                  ->
  unit Lwt.t

(** A registered client contains basic information about the client, its ID
    in the database and its credentials. It represents a client which is
    registered in the database.
 *)
type registered_client

(** Get the ID of a registered client. It's the ID from the database. *)
val id_of_registered_client          :
  registered_client  ->
  Os_types.OAuth2.Client.id

(** Get the client information as {!client} type of a registered client. *)
val client_of_registered_client      :
  registered_client  ->
  client

(** Get the credentials of a registered clients. *)
val credentials_of_registered_client :
  registered_client  ->
  Os_oauth2_shared.client_credentials

(** Build a value of type {!registered_client}. *)
val to_registered_client             :
  Os_types.OAuth2.Client.id           ->
  client                              ->
  Os_oauth2_shared.client_credentials ->
  registered_client

(** Return the registered client which has [client_id] as client id. Data are
    retrieved from database.
 *)
val registered_client_of_client_id   :
  Os_types.OAuth2.client_id         ->
  registered_client Lwt.t

(** List all registered clients from [min_id] (default [0]) with a limit of
    [limit] (default [10]).
 *)
val list_clients :
  ?min_id:Os_types.OAuth2.Client.id ->
  ?limit:Int64.t                    ->
  unit                              ->
  registered_client list Lwt.t

(** {2 Scopes, tokens and basic implementations of them. } *)

(** Interface for scopes. *)
module type SCOPE =
  sig
    (** Scope is a list of permissions. *)
    type scope

    val scope_of_str :
      string ->
      scope

    val scope_to_str :
      scope ->
      string

    (** Return [true] if the scope asked by the client is
        allowed, else [false].

        You can implement simple check functions by only checking if all
        elements of the scopes list are defined but you can also have the case
        where two scopes can't be asked at the same time.
     *)
    val check_scope_list :
      scope list ->
      bool
  end

(** Interface for tokens. *)
module type TOKEN =
  sig
    (** List of permissions. Used to type the [scope] field in {!saved_token} *)
    type scope

    (** Saved token representation. The type is abstract to let the choice of
        the implementation.
        A token must contain at least:
        - the userid to know which user authorized.
        - the OAuth2.0 client ID to know the client to which the token is
          assigned. The ID is related to the database.
        - a value (the token value).
        - the token type (for example ["bearer"]).
        - the scopes list (of type {!scope}). Used to know which data the data
        service must send.
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
    val cycle_duration : int

    (** The number of cycle. *)
    val number_of_cycle : int

    (** Return the client ID. *)
    val id_client_of_saved_token  :
      saved_token ->
      Os_types.OAuth2.Client.id

    (** Return the userid of the user who authorized. *)
    val userid_of_saved_token     :
      saved_token ->
      Os_types.User.id

    (** Return the token value. *)
    val value_of_saved_token      :
      saved_token ->
      string

    (** Return the token type. *)
    val token_type_of_saved_token :
      saved_token ->
      string

    (** Return the scope asked by the client. *)
    val scope_of_saved_token      :
      saved_token ->
      scope list

    (** Return the number of passed cycle. *)
    val counter_of_saved_token    :
      saved_token ->
      int ref

    (** Return [true] if the token already exists. *)
    val token_exists              :
      saved_token                 ->
      bool

    (** Generate a token value. *)
    val generate_token_value      :
      unit                        ->
      string

    (** Generate a new token. *)
    val generate_token            :
      id_client:Os_types.OAuth2.Client.id ->
      userid:Os_types.User.id             ->
      scope:scope list                    ->
      saved_token Lwt.t

    (** Save a token. *)
    val save_token                :
      saved_token                 ->
      unit

    (** Remove a saved token. *)
    val remove_saved_token        :
      saved_token                 ->
      unit

    (** Return the saved token assigned to the client with given ID and
        value.
     *)
    val saved_token_of_id_client_and_value :
      Os_types.OAuth2.Client.id   ->
      string                      ->
      saved_token

    (** List all saved tokens *)
    val list_tokens               :
      unit                        ->
      saved_token list

    (** Return the saved token as a JSON. Used to send to the client. *)
    val saved_token_to_json       :
      saved_token                 ->
      Yojson.Safe.json
  end

(** Interface for OAuth2.0 servers.
    See also {!MakeServer}.
 *)
module type SERVER =
  sig
    (** The following types and functions related to tokens and scopes are
        aliases to the same types and functions from the modules types given in
        the functor {!MakeServer}. These aliases avoid to know the modules used
        to build the client.

        See {!SCOPE} and {!TOKEN} modules for documentations about these types
        and functions.
     *)

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

    type saved_token

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

    (** [set_userid_of_request_info_code client_id state userid] TODO *)
    val set_userid_of_request_info_code :
      string ->
      string ->
      Os_types.User.id ->
      unit

    (** {3 Send authorization code functions. } *)

    (**
      These functions can be called by the authorization handler
      {!authorization_handler}.

      Using this function avoids to know how OAuth2.0 works and to implement
      the redirection manually.
    *)

    (** [send_authorization_code state client_id] sends
        an authorization code to the [redirect_uri] of the client with client ID
        [client_id]. [redirect_uri] is retrieved from the state [state].

     *)
    val send_authorization_code :
      string                    ->
      Os_types.OAuth2.client_id ->
      Eliom_registration.Html.page Lwt.t

    (** [send_authorization_code_error ?error_description ?error_uri error state
        redirect_uri] does a change page to [redirect_uri] with the
        corresponding error description ([error_description]) and URI
        ([error_uri]).
     *)
    val send_authorization_code_error :
      ?error_description:string option               ->
      ?error_uri:string option                       ->
      Os_oauth2_shared.error_authorization_code_type ->
      string                                         ->
      Ocsigen_lib.Url.t                              ->
      Eliom_registration.Html.page Lwt.t

    (** {4 RPC to use when the resource owner authorize or decline. } *)

    (** [rpc_resource_owner_authorize state client_id] is the RPC to use
        client-side when the resource owner has authorized.
     *)
    val rpc_resource_owner_authorize  :
      (
        string * Os_types.OAuth2.client_id,
        Eliom_registration.Html.page
      )
      Eliom_client.server_function

    (** [rpc_resource_owner_decline state redirect_uri] is the RPC to use
        client-side when the resource owner has declined.
     *)
    val rpc_resource_owner_decline    :
      (
        string * Ocsigen_lib.Url.t,
        Eliom_registration.Html.page
      )
      Eliom_client.server_function

    (** {5 Authorization and token services/handlers } *)

    (** When registering, some GET parameters are mandatory in the RFC.
        Functions ({!authorization_service} and {!token_service}) are defined to
        create the services for authorization and token.

        There are not abstract because it's known due to RFC.
     *)

    (** Type of the pre-defined service for authorization. It's a GET
        service.
     *)
    type authorization_service =
      (string *
        (Os_types.OAuth2.client_id * (Ocsigen_lib.Url.t * (string * string))
      ),
      unit,
      Eliom_service.get,
      Eliom_service.att,
      Eliom_service.non_co,
      Eliom_service.non_ext,
      Eliom_service.reg, [ `WithoutSuffix ],
      [ `One of string ]
      Eliom_parameter.param_name *
      ([ `One of Os_types.OAuth2.client_id ]
       Eliom_parameter.param_name *
       ([ `One of Ocsigen_lib.Url.t ]
        Eliom_parameter.param_name *
        ([ `One of string ]
         Eliom_parameter.param_name *
         [ `One of string ]
         Eliom_parameter.param_name))),
      unit, Eliom_service.non_ocaml)
      Eliom_service.t

    (** [authorization_service path] returns a service for the authorization.
        You can use the handler {!authorization_handler}.
     *)
    val authorization_service :
      Eliom_lib.Url.path ->
      authorization_service

    (** The function type for the authorization handler. This type is defined to
        have a clearer interface in {!authorization_handler}.
     *)
    type authorization_handler  =
      state:string                        ->
      client_id:Os_types.OAuth2.client_id ->
      redirect_uri:Ocsigen_lib.Url.t      ->
      scope:scope list                    ->
      Eliom_registration.Html.page Lwt.t (* Return value of the handler *)

    (** [authorize_handler handler] returns a handler for the authorization URL.
        You can use the service {!authorization_service}.
     *)
    val authorization_handler :
      authorization_handler ->
      (
        (string * (Os_types.OAuth2.client_id *
            (Ocsigen_lib.Url.t * (string * string)))
        )                                                   ->
        unit                                                ->
        Eliom_registration.Html.page Lwt.t
      )

    (** Type of the pre-defined service for token. It's a POST service. *)
    type token_service =
      (unit,
      string * (string * (Ocsigen_lib.Url.t * (string *
        Os_types.OAuth2.client_id))),
      Eliom_service.post,
      Eliom_service.att,
      Eliom_service.non_co,
      Eliom_service.non_ext,
      Eliom_service.reg,
      [ `WithoutSuffix ],
      unit,
      [ `One of string ] Eliom_parameter.param_name *
      ([ `One of string ] Eliom_parameter.param_name *
        ([ `One of Ocsigen_lib.Url.t ] Eliom_parameter.param_name *
          ([ `One of string ] Eliom_parameter.param_name *
            [ `One of Os_types.OAuth2.client_id ] Eliom_parameter.param_name))),
      Eliom_registration.String.return)
      Eliom_service.t

    (** [token_service path] returns a service for the access token URL.
        You can use the handler {!token_handler}.
     *)
    val token_service :
      Ocsigen_lib.Url.path ->
      token_service

    (** Handler for the access token URL.
        You can use the service {!token_service}.
     *)
    val token_handler :
      (
        unit                                                           ->
        (string * (string *
          (Ocsigen_lib.Url.t * (string * Os_types.OAuth2.client_id)))) ->
        Eliom_registration.String.result Lwt.t
      )
  end

(** [MakeBasicToken (Scope)] returns a module of type {!TOKEN} with scope
    dependency from the module [Scope].
 *)
module MakeBasicToken : functor
  (Scope : SCOPE) -> (TOKEN with type scope = Scope.scope)

(** [MakeServer (Scope) (Token)] returns a module of type {!SERVER} with scope
    dependency from the module [Scope] and token dependency from [Token].

    {!SCOPE.scope} and {!TOKEN.scope} must have the same type.
 *)
module MakeServer : functor
  (Scope : SCOPE) -> functor
  (Token : (TOKEN with type scope = Scope.scope)) ->
  (SERVER with
    type scope = Scope.scope and
    type saved_token = Token.saved_token
  )

(** Basic scope. *)
module Basic_scope :
  sig
    (** Available scopes. When doing a request, [OAuth] is automatically
        set.
     *)
    type scope =
      | OAuth (** Mandatory in each requests (due to RFC).*)
      | Firstname (** Get access to the first name *)
      | Lastname (** Get access to the last name *)
      | Email (** Get access to the email *)
      | Unknown (** Used when an unknown scope is given. *)

    (** Get a string representation of the scope. {{!scope}Unknown} string
        representation is the empty string.
     *)
    val scope_to_str : scope -> string

    (** Convert a string scope to {!scope} type. *)
    val scope_of_str : string -> scope

    (** [check_scope_list scope_list] returns [true] if every element in
        [scope_list] is an available scope value.
        If the list contains only [OAuth] or if the list doesn't contain
        [OAuth] (mandatory scope in RFC), returns [false].
        If an unknown scope value is in list (represented by [Unknown]),
        it returns [false].
     *)
    val check_scope_list : scope list -> bool
  end

(** Basic token, based on {!Basic_scope}.

    A token value is a random string of length {!Os_oauth2_shared.size_token}.
    The expiration time is set to [10] minutes with [10] cycles of [60] seconds.

    Tokens are represented as records and have exactly the fields available by
    the interface.

    The token type is ["bearer"].

    The related JSON contains the fields:
    - ["token_type"] with value ["bearer"].
    - ["token"] with the token value.
    - ["expires_in"] with the value [cycle_duration * number_of_cycle] i.e. 600
    seconds.
 *)
module Basic_token : TOKEN

(** Basic server, based on {!Basic_scope} and {!Basic_token}. *)
module Basic : (SERVER with type scope = Basic_scope.scope)
