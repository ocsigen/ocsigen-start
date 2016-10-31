open Os_oauth2_shared

(* -------------------------------- *)
(* ---------- Exceptions ---------- *)

(* About state *)
exception State_not_found

(* About client *)
exception No_such_client

(* About server *)
exception Server_id_exists
exception No_such_server

(* About saved token *)
exception No_such_saved_token
exception Bad_JSON_respoonse

(* ---------- Exceptions ---------- *)
(* -------------------------------- *)

(* ----------------------------------- *)
(* Type of registered OAuth2.0 server. *)

type registered_server

val id_of_registered_server                 :
  registered_server                       ->
  int64

val server_id_of_registered_server          :
  registered_server                       ->
  string

val authorization_url_of_registered_server  :
  registered_server                       ->
  string

val token_url_of_registered_server          :
  registered_server                       ->
  string

val data_url_of_registered_server           :
  registered_server                       ->
  string

val client_credentials_of_registered_server :
  registered_server                       ->
  client_credentials

val to_registered_server                    :
  id:int64                                ->
  server_id:string                        ->
  authorization_url:string                ->
  token_url:string                        ->
  data_url:string                         ->
  client_credentials:client_credentials   ->
  registered_server

val list_servers        :
  unit                ->
  registered_server list Lwt.t

(** Type of registered OAuth2.0 server. Only used client side. *)
(** ---------------------------------------------------------- *)

(** ------------------------------- *)
(** Save and remove a OAuth2 server *)
(** If a OAuth2 server is already registerd with server_id, raise an error
 * Server_id_exists.
 * OK
 *)

val save_server :
  server_id:string                  ->
  server_authorization_url:string   ->
  server_token_url:string           ->
  server_data_url:string            ->
  client_id:string                  ->
  client_secret:string              ->
  unit Lwt.t

val remove_server_by_id :
  int64                             ->
  unit Lwt.t

(** Save and remove a OAuth2 server *)
(** ------------------------------- *)

(** ------------------ *)
(** Client credentials *)

(** Get the client credientials for a given OAuth2.0 server. OK *)
val get_client_credentials : server_id:string -> client_credentials Lwt.t

(** Client credentials *)
(** ------------------ *)

module type SCOPE = sig
  type scope

  val default_scope : scope list

  val scope_of_str :
    string ->
    scope

  val scope_to_str :
    scope ->
    string
end

module type TOKEN = sig
  (** Represents a saved token. Tokens are registered in the volatile memory with
   * scope default_global_scope.
   *)
  type saved_token

  val saved_tokens : saved_token list ref

  (* Tokens must expire after a certain amount of time. For this, a timer checks
   * all [timeout] seconds and if the token has been generated after [timeout] *
   * [number_of_timeout] seconds, we remove it.
   *)
  (** [timeout] is the number of seconds after how many we need to check if
    * saved tokens are expired.
   *)
  val timeout : int

  (** [number_of_timeout] IMPROVEME DOCUMENTATION *)
  val number_of_timeout : int

  (** ---------------------------- *)
  (** Getters for the saved tokens *)

  val id_server_of_saved_token :
    saved_token ->
    int64

  val value_of_saved_token                 :
    saved_token ->
    string

  val token_type_of_saved_token            :
    saved_token ->
    string

  (** Representing the number of times the token has been checked by the timeout.
   * Must be of type int ref.
   *)
  val counter_of_saved_token               :
    saved_token  ->
    int ref

  (** Getters for the saved tokens *)
  (** ---------------------------- *)

  (** Parse the JSON file returned by the token server and returns the
   * corresponding save_token OCaml type.
   * Must raise Bad_JSON_response if all needed information are not given.
   * NOTE: Must ignore unrecognized JSON attributes.
   *)
  val parse_json_token    :
    int64                ->
    Yojson.Basic.json    ->
    saved_token

  val saved_token_of_id_server_and_value   :
    int64               ->
    string              ->
    saved_token

  val save_token          :
    saved_token         ->
    unit

  val list_tokens         :
    unit                ->
    saved_token list

  val remove_saved_token  :
    saved_token         ->
    unit
  end

module type CLIENT = sig
  (* -------------------------- *)
  (* --------- Scope ---------- *)

  type scope

  val default_scope : scope list

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

  (* --------- Scope ---------- *)
  (* -------------------------- *)

  (** ---------------------------- *)
  (** Initialize a OAuth2.0 client *)

  (** When register, clients must specify a redirect uri where the code will
   * be sent as GET parameter (or the authorization code error).
   * register_redirect_uri ~redirect_uri ~success_redirection ~error_rediction
   * registers two services at the url [link] :
       * - for successfull authorization code response.
       * - for error authorization code response.
   * 1. In the case of a successfull authorization code, this service will
   * request an access token to the token server and if the token server
   * responds with success, the token is saved in the database and a
   * redirection is done to the service [success_redirection].
   * 2. In the case of an error response (while requesting an authorization code
   * or a token, we redirect the user to the service [error_redirection].
   *)

  val register_redirect_uri :
    redirect_uri:string ->
    success_redirection:
      Eliom_service.non_ocaml Eliom_registration.Redirection.page ->
    error_redirection:
      Eliom_service.non_ocaml Eliom_registration.Redirection.page ->
    unit Lwt.t

  (** Initialize a OAuth2.0 client *)
  (** ---------------------------- *)

  (** ---------------------------------------- *)
  (** ---------- Authorization code ---------- *)

  (**
   * request_authorization_code
   *  ~redirect_uri ~server_id ~scope=["firstname", "lastname"]
   * Requests an authorization code to the OAuth2 server represented by
   * ~server_id to get access to the firstname and lastname of the resource
   * owner. ~server_id is needed to get credentials. ~redirect_uri is used to
   * redirect the user-agent on the client OAuth2.
   *
   * You will never manipulate the authorization code. The code is temporarily
   * server side saved until expiration in the HTTP parameter.
   * The next time you request an access token, authorization code will
   * be checked and if it's not expired, request an access token to the
   * OAuth2.0 server.
   *
   * The optional default scope is to be compatible with OAuth2.0 which
   * doesn't respect "oauth" (mandatory in the RFC) in scope.
   * IMPROVEME: Use string list to add multiple default scope?
   *)
  val request_authorization_code :
    redirect_uri:string   ->
    server_id:string      ->
    scope:scope list ->
    unit Lwt.t

  (** ---------- Authorization code ---------- *)
  (** ---------------------------------------- *)

  (* ---------------------------------- *)
  (* ----------- Saved token ---------- *)

  (** Represents a saved token. Tokens are registered in the volatile memory with
   * scope default_global_scope.
   *)
  type saved_token

  (** ---------------------------- *)
  (** Getters for the saved tokens *)

  val id_server_of_saved_token    : saved_token -> int64
  val value_of_saved_token        : saved_token -> string
  val token_type_of_saved_token   : saved_token -> string

  (** Getters for the saved tokens *)
  (** ---------------------------- *)

  (** Token.saved_token_of_id_server_and_value. In this way, it can be used
   * outside independently of the Token module given in the functor MakeClient
   *)
  val saved_token_of_id_server_and_value :
    int64               ->
    string              ->
    saved_token

  (** Token.list_tokens. In this way, it can be used outside independently of
   * the Token module given in the functor MakeClient
   *)
  val list_tokens         :
    unit                ->
    saved_token list

  (** Token.remove_saved_token. In this way, it can be used outside
   * independently of the Token module given in the functor MakeClient
   *)
  val remove_saved_token  :
    saved_token         ->
    unit

  (* ----------- Saved token ---------- *)
  (* ---------------------------------- *)
end

(* -------------------------------------------------------------------------- *)
(* ------------------------------ Basic modules ----------------------------- *)

(** Basic_scope is a SCOPE module representing a basic scope list (firstname,
 * lastname and email).
 * This scope representation is used in Os_oauth2_server.Basic so you can to
 * use this module if the OAuth2.0 server is an instance of
 * Os_oauth2_server.Basic.
 *
 * See Os_oauth2_client.Basic for a basic OAuth2 client compatible with
 * the OAuth2 server Os_oauth2_server.Basic.
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

(** Basic_token is a TOKEN module representing a basic token (id_server, value
 * and token_type.
 * This token representation is used in Os_oauth2_server.Basic so you can to
 * use this module if the OAuth2 server is an instance of
 * Os_oauth2_server.Basic.
 *
 * See Os_oauth2_client.Basic for a basic OAuth2 client compatible with
 * the OAuth2 server Os_oauth2_server.Basic.
 *)
module Basic_token : TOKEN

(** Build a OAuth2 client from a module of type SCOPE and a module of type
 * TOKEN. In this way, you have a personalized OAuth2.0 client.
 *)
module MakeClient : functor
  (Scope : SCOPE) -> functor
  (Token : TOKEN) ->
  (CLIENT with
    type scope = Scope.scope and
    type saved_token = Token.saved_token
  )

(** Basic OAuth2 client, compatible with OAuth2.0 server
 * Os_oauth2_server.Basic.
 *)
module Basic : (CLIENT with type scope = Basic_scope.scope and type saved_token
= Basic_token.saved_token)

(* ------------------------------ Basic modules ----------------------------- *)
(* -------------------------------------------------------------------------- *)
