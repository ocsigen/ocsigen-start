open Os_oauth2_shared
open Eliom_parameter
open Lwt.Infix

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

type registered_server =
  {
    id : int64 ;
    server_id : string ;
    authorization_url : string ;
    token_url : string ;
    data_url : string ;
    client_credentials : client_credentials
  }

let id_of_registered_server s                 = s.id
let server_id_of_registered_server s          = s.server_id
let authorization_url_of_registered_server s  = s.authorization_url
let token_url_of_registered_server s          = s.token_url
let data_url_of_registered_server s           = s.data_url
let client_credentials_of_registered_server s = s.client_credentials

let to_registered_server
  ~id ~server_id ~authorization_url ~token_url ~data_url
  ~client_credentials =
  {
    id ; server_id ; authorization_url ; token_url ; data_url ;
    client_credentials
  }

let list_servers () =
  let%lwt servers = Os_db.OAuth2_client.list_servers () in
  Lwt.return (
    List.map (
      fun ( id, server_id, authorization_url, token_url, data_url, client_id,
          client_secret) ->
        to_registered_server
        ~id ~server_id ~authorization_url ~token_url ~data_url
        ~client_credentials:
          (client_credentials_of_str client_id client_secret)
      ) servers
  )

(** Type of registered OAuth2.0 server. Only used client side. *)
(** ---------------------------------------------------------- *)

(** --------------------------------------------- *)
(** Get client credentials and server information *)

let get_client_credentials ~server_id =
  try%lwt
    (Os_db.OAuth2_client.get_client_credentials ~server_id)
    >>=
    (fun (id, secret) ->
      Lwt.return (client_credentials_of_str ~client_id:id ~client_secret:secret)
    )
  with Os_db.No_such_resource -> Lwt.fail No_such_server

let get_server_url_authorization ~server_id =
  try%lwt
    let%lwt url =
      Os_db.OAuth2_client.get_server_authorization_url ~server_id
    in
    Lwt.return (Os_oauth2_shared.prefix_and_path_of_url url)
  with Os_db.No_such_resource -> Lwt.fail No_such_server

let get_server_url_token ~server_id =
  try%lwt
    Os_db.OAuth2_client.get_server_token_url ~server_id
  with Os_db.No_such_resource -> Lwt.fail No_such_server

(** Get client credentials and server information *)
(** --------------------------------------------- *)

(** ------------------------------- *)
(** Save and remove a OAuth2 server *)

let save_server
  ~server_id ~server_authorization_url ~server_token_url
  ~server_data_url ~client_id ~client_secret =
  let%lwt exists = Os_db.OAuth2_client.server_id_exists server_id in
  if not exists then
  (
    Lwt.ignore_result (
      Os_db.OAuth2_client.save_server
        ~server_id ~server_authorization_url ~server_token_url
        ~server_data_url ~client_id ~client_secret
    );
    Lwt.return ()
  )
  else Lwt.fail Server_id_exists

let remove_server_by_id id =
  try%lwt
    Os_db.OAuth2_client.remove_server_by_id id
  with Os_db.No_such_resource -> Lwt.fail No_such_server

(** Save and remove a OAuth2 server *)
(** ------------------------------- *)

(** ----------------------------------------------------------- *)
(** Scope module type. See the eliomi file for more information *)

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

(** Scope module type. See the eliomi file for more information *)
(** ----------------------------------------------------------- *)

(** ----------------------------------------------------------- *)
(** Token module type. See the eliomi file for more information *)

module type TOKEN = sig
  (** Represents a saved token *)
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

(** Token module type. See the eliomi file for more information *)
(** ----------------------------------------------------------- *)

(** ------------------------------------------------------------ *)
(** Client module type. See the eliomi file for more information *)

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

  (* ----------- Saved token ---------- *)
  (* ---------------------------------- *)
end

(** Client module type. See the eliomi file for more information *)
(** ------------------------------------------------------------ *)

(** -------------------------------------------------------- *)
(** Functor to create a Client from a Scope and Token module *)

module MakeClient
  (Scope : SCOPE)
  (Token : TOKEN) :
    (CLIENT with
      type scope = Scope.scope and
      type saved_token  = Token.saved_token
    ) = struct

  (* -------------------------- *)
  (* --------- Scope ---------- *)

  type scope = Scope.scope

  let default_scope = Scope.default_scope

  let scope_of_str = Scope.scope_of_str

  let scope_to_str = Scope.scope_to_str

  let scope_list_of_str_list l = List.map scope_of_str l

  let scope_list_to_str_list l = List.map scope_to_str l

  (* --------- Scope ---------- *)
  (* -------------------------- *)

  (* ---------------------------------------- *)
  (* --------- Request information ---------- *)

  type request_info =
  {
    state     : string          ;
    server_id : string          ;
    scope     : scope list ;
  }

  let state_of_request_info v      = v.state
  let server_id_of_request_info v  = v.server_id
  let scope_of_request_info v      = v.scope

  (* Remember server_id, redirect_uri and scope for an authorization code
   * request. site_scope is used because, with default_process_scope
   * and default_session_group, if the page is reloaded, it is considered to
   * be a new process and the reference is removed. While redirection,
   * volatile reference saved with default_session_group are removed.
   *)

  let request_info : request_info list ref = ref []

  (** Print all registered request information *)
  let print_request_info_state_list () =
    let states = (! request_info) in
    if List.length states = 0 then
      print_endline "No registered states"
    else
      List.iter
        (fun r ->
          print_endline ("State: " ^ (state_of_request_info r)) ;
          print_endline ("Server_id: " ^ (server_id_of_request_info r))
        )
        states

  (** add_request_info [state] [server_id] [scope] creates a new
   * request_info value and add it in the volatile reference.
   *)
  let add_request_info state server_id scope =
    let new_request_info = {state ; server_id ; scope} in
    request_info := (new_request_info :: (! request_info))

  (** remove_request_info [state] removes the
   * request_info which has [state] as state.
   *)
  let remove_request_info_by_state state =
    request_info :=
      (remove_from_list (fun x -> x.state = state) (!request_info))

  (** Get the request_info value which has state [state] *)
  let request_info_of_state state =
    let rec request_info_of_state_intern l = match l with
    | [] -> raise State_not_found
    | head::tail ->
        if head.state = state then head
        else request_info_of_state_intern tail
    in
    request_info_of_state_intern (! request_info)

  (* ---------- Request information ---------- *)
  (* ----------------------------------------- *)

  (** ---------------------------------------- *)
  (** ---------- Authorization code ---------- *)

  (** Generate a random state for the authorization process. *)
  (** IMPROVEME: add it in the interface to let the OAuth2.0 client generates
   * the state, pass it to request_authorization_code and use this state (and
   * the server_id) to be able to get back the token ? It means we need to add
   * the state in the token, which can be done when adding the access_token.
   *)
  let generate_state () =
    Os_oauth2_shared.generate_random_string Os_oauth2_shared.size_state

  (* TODO: add a optional parameter for other parameters to send. *)
  let request_authorization_code ~redirect_uri ~server_id ~scope
    =
    let%lwt (prefix, path)       = get_server_url_authorization ~server_id  in
    let scope_str_list         =
      scope_list_to_str_list (default_scope @ scope)
    in
    (* ------------------------------ *)
    (* in raw to easily change later. *)
    let response_type          = "code" in
    (* ------------------------------ *)
    let%lwt client_credentials = get_client_credentials ~server_id        in
    let client_id              = client_credentials_id client_credentials in
    let state                  = generate_state ()                        in

    let service_url            = Eliom_service.extern
      ~prefix
      ~path
      ~meth:param_authorization_code
      ()
    in
    let scope_str              = String.concat " " scope_str_list         in
    add_request_info state server_id scope;
    ignore ([%client (
      Eliom_client.change_page
        ~service:~%service_url
        (~%response_type, (~%client_id, (~%redirect_uri, (~%scope_str,
        ~%state))))
        ()
      : unit Lwt.t)
    ]);

    Lwt.return ()
  (** ------------------ *)

  (** ---------- Authorization code ---------- *)
  (** ---------------------------------------- *)

  (* ---------------------------------- *)
  (* ----------- Saved token ---------- *)

  type saved_token                       = Token.saved_token

  (* ------- *)
  (* getters *)

  let id_server_of_saved_token           = Token.id_server_of_saved_token

  let value_of_saved_token               = Token.value_of_saved_token

  let token_type_of_saved_token          = Token.token_type_of_saved_token

  (* getters *)
  (* ------- *)

  let saved_token_of_id_server_and_value =
    Token.saved_token_of_id_server_and_value

  let list_tokens                        = Token.list_tokens

  let remove_saved_token                 = Token.remove_saved_token

  (* ----------- Saved token ---------- *)
  (* ---------------------------------- *)

  (** OCaml representation of a token. This is the OCaml equivalent
   * representation of the JSON returned by the token server
   *)
  type token_json =
  {
    token_type  : string ;
    value       : string ;
  }

  (** Create a token with the type and the corresponding value *)
  let token_json_of_str token_type value = {token_type ; value}

  (** ------- *)
  (** Getters *)

  let token_type_of_token_json t = t.token_type
  let value_of_token_json t      = t.value

  (** Getters *)
  (** ------- *)

  (** Request a token to the server represented as ~server_id in the
   * database. Saving it in the database allows to keep it a long time.
   * TODO: add an optional parameter for other parameters to send.
   * NOTE: an exception No_such_server is raised if [server_id] doesn't exist.
   *)
  let request_access_token ~state ~code ~redirect_uri ~server_id =
    let%lwt client_credentials  = get_client_credentials ~server_id in
    let%lwt server_url          = get_server_url_token ~server_id in
    (* ----------------------------- *)
    (* in raw to easily change later. *)
    let grant_type              = "authorization_code" in
    (* ----------------------------- *)
    let client_id               =
      client_credentials_id client_credentials
    in
    let client_secret           =
      client_credentials_secret client_credentials
    in

    let base64_credentials      =
      (B64.encode (client_id ^ ":" ^ client_secret))
    in
    let content                 =
      "grant_type=" ^ grant_type ^
      "&code=" ^ code ^
      "&redirect_uri=" ^ (Ocsigen_lib.Url.encode redirect_uri) ^
      "&state=" ^ state ^
      "&client_id=" ^ client_id
    in
    let headers                 =
      Http_headers.add
        Http_headers.authorization
        ("Basic " ^ base64_credentials)
        Http_headers.empty
    in
    Ocsigen_http_client.post_string_url
      ~headers
      ~content
      ~content_type:("application", "x-www-form-urlencoded")
      server_url

  (** ---------- Token ---------- *)
  (** --------------------------- *)

  (** ---------------------------- *)
  (** Initialize a OAuth2.0 client *)

  (** Use a default handler for the moment *)
  let register_redirect_uri
    ~redirect_uri ~success_redirection ~error_redirection
  =
    let (prefix, path) = Os_oauth2_shared.prefix_and_path_of_url redirect_uri in
    let success =
      Eliom_service.create
        ~path:(Eliom_service.Path path)
        ~meth:param_authorization_code_response
        ()
    in
    let error =
      Eliom_service.create
        ~path:(Eliom_service.Path path)
        ~meth:param_authorization_code_response_error
        ()
    in

    update_list_timer
      Token.timeout
      (fun x -> let c = Token.counter_of_saved_token x in !c >= Token.number_of_timeout)
      (fun x -> let c = Token.counter_of_saved_token x in incr c)
      Token.saved_tokens
      ();

    (* We register the service while we succeed to get a authorization code.
     * This service will request a token with request_token.
     *)
    Eliom_registration.Redirection.register
      ~service:success
      (fun (code, state) () ->
        (* --------------------- *)
        (* Get the server_id which will be used to get client credentials and
         * the the token server
         *)
        let request_info        =
          request_info_of_state state
        in
        let server_id           =
          (server_id_of_request_info request_info)
        in
        let%lwt id              =
          Os_db.OAuth2_client.id_of_server_id server_id
        in
        (* --------------------- *)

        (* Request a token. The content reponse is JSON. response_token is
         * of type Ocsigen_http_frame.t *)
        let%lwt response_token  =
          request_access_token ~state ~code ~redirect_uri ~server_id
        in
        let _ = remove_request_info_by_state state in
        (* read the frame content to get the JSON as string *)
        let%lwt content =
          match Ocsigen_http_frame.(response_token.frame_content) with
          | None -> Lwt.return "" (* FIXME: raise an exception *)
          | Some x -> Os_lib.Http.string_of_stream x
        in
        let json_content_response =
          Yojson.Safe.to_basic (Yojson.Safe.from_string content)
        in
        let saved_token  = Token.parse_json_token id json_content_response in
        Token.save_token saved_token;
        (* Some code checking the code, requesting a token, etc *)
        Lwt.return success_redirection
      );

    Eliom_registration.Redirection.register
      ~service:error
      (fun (error, (error_description, error_uri)) () ->

        (* Do we do something else? *)
        Lwt.return error_redirection
      );

    Lwt.return ()

  (** Initialize a OAuth2.0 client *)
  (** ---------------------------- *)

  (** --------------------------------- *)
  (** Tokens *)

  (** Tokens *)
  (** --------------------------------- *)
end

(** Functor to create a Client from a Scope and Token module *)
(** -------------------------------------------------------- *)

(* -------------------------------------------------------------------------- *)
(* ------------------------------ Basic modules ----------------------------- *)

module Basic_scope =
  struct
    type scope = OAuth | Firstname | Lastname | Email | Unknown

    let default_scope = [ OAuth ]

    let scope_to_str = function
      | OAuth       -> "oauth"
      | Firstname   -> "firstname"
      | Lastname    -> "lastname"
      | Email       -> "email"
      | Unknown     -> ""

    let scope_of_str = function
      | "oauth"     -> OAuth
      | "firstname" -> Firstname
      | "lastname"  -> Lastname
      | "email"     -> Email
      | _           -> Unknown
  end

(** Basic_token is a TOKEN module representing a basic token (id_server, value
 * and token_type.
 * This token representation is used in Os_oauth2_server.Basic so you need to
 * use this module if the OAuth2 server is a instance of
 * Os_oauth2_server.Basic.
 *
 * See Os_oauth2_client.Basic for a basic OAuth2 client compatible with
 * the OAuth2 server Os_oauth2_server.Basic.
 *)
module Basic_token : TOKEN = struct
  type saved_token =
  {
    id_server   : int64           ;
    value       : string          ;
    token_type  : string          ;
    counter     : int ref
  }

  let timeout             = 10
  let number_of_timeout   = 1

  (* ------- *)
  (* getters *)

  let id_server_of_saved_token t      = t.id_server
  let value_of_saved_token t          = t.value
  let token_type_of_saved_token t     = t.token_type
  let counter_of_saved_token t        = t.counter

  (* getters *)
  (* ------- *)

  (** Parse the JSON file returned by the token server and returns the
   * corresponding save_token OCaml type.
   * In this way, it's easier to work with the token response.
   * NOTE: Ignore unrecognized JSON attributes.
   *)
  let parse_json_token id_server t =
    try
      let value       =
        Yojson.Basic.Util.to_string (Yojson.Basic.Util.member "token" t)
      in
      let token_type  =
        Yojson.Basic.Util.to_string (Yojson.Basic.Util.member "token_type" t)
      in
      { id_server ; value ; token_type ; counter = ref 0}
    with _ -> raise Bad_JSON_respoonse

  let saved_tokens : saved_token list ref = ref []

  let save_token token =
    saved_tokens := (token :: (! saved_tokens))

  let saved_token_of_id_server_and_value id_server value =
    let saved_tokens_tmp = ! saved_tokens in
    let rec locale = function
    | [] -> raise No_such_saved_token
    | head::tail ->
        if head.id_server = id_server && head.value = value
        then head
        else locale tail
    in
    locale saved_tokens_tmp

  let list_tokens () =
    !saved_tokens

  let remove_saved_token token =
    let value     = value_of_saved_token token     in
    let id_server = id_server_of_saved_token token in
    saved_tokens :=
      (
        remove_from_list
        (fun (x : saved_token) ->
          x.value = value && x.id_server = id_server
        )
        (!saved_tokens)
      )
end

(** Basic OAuth2 client, compatible with OAuth2.0 server
 * Os_oauth2_server.Basic.
 *)
module Basic = MakeClient (Basic_scope) (Basic_token)

(* ------------------------------ Basic modules ----------------------------- *)
(* -------------------------------------------------------------------------- *)
