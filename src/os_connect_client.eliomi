exception Bad_JSON_response

exception No_such_saved_token

module type IDTOKEN =
  sig
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

  val id_token_of_saved_token              :
    saved_token ->
    Jwt.t

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

module Basic_scope :
  sig
    type scope = OpenID | Firstname | Lastname | Email | Unknown

    val default_scope : scope list

    val scope_to_str : scope -> string

    val scope_of_str : string -> scope
  end

module Basic_ID_token : IDTOKEN

module Basic : (Os_oauth2_client.CLIENT with
  type scope = Basic_scope.scope and
  type saved_token = Basic_ID_token.saved_token)
