exception No_such_saved_token

module type IDTOKEN =
  sig
    type scope

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

    (* ------- *)
    (* getters *)

    val id_client_of_saved_token :
      saved_token ->
      int64

    val userid_of_saved_token :
      saved_token ->
      int64

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
      id_client:int64             ->
      userid:int64                ->
      scope:scope list            ->
      saved_token Lwt.t

    (* Save a token *)
    val save_token                :
      saved_token                 ->
      unit

    val remove_saved_token        :
      saved_token                 ->
      unit

    val saved_token_of_id_client_and_value :
      int64                       ->
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
