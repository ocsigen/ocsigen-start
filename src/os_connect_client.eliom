open Os_oauth2_shared

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

module Basic_scope =
  struct
  (* --------------------------- *)
  (* ---------- Scope ---------- *)

  type scope = OpenID | Firstname | Lastname | Email | Unknown

  let default_scope = [ OpenID ]

  let scope_to_str = function
    | OpenID      -> "openid"
    | Firstname   -> "firstname"
    | Lastname    -> "lastname"
    | Email       -> "email"
    | Unknown     -> ""

  let scope_of_str = function
    | "openid"    -> OpenID
    | "firstname" -> Firstname
    | "lastname"  -> Lastname
    | "email"     -> Email
    | _           -> Unknown

  (* ---------- Scope ---------- *)
  (* --------------------------- *)
  end

module Basic_ID_token : IDTOKEN =
    struct
      type saved_token =
      {
        id_server   : int64           ;
        value       : string          ;
        token_type  : string          ;
        counter     : int ref         ;
        id_token    : Jwt.t
      }

      let saved_tokens : saved_token list ref = ref []

      let timeout           = 10

      let number_of_timeout = 1

      (* ------- *)
      (* getters *)

      let id_server_of_saved_token t      = t.id_server

      let value_of_saved_token t          = t.value

      let token_type_of_saved_token t     = t.token_type

      let id_token_of_saved_token t       = t.id_token

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
          let id_token =
            Jwt.t_of_token
            (
              Yojson.Basic.Util.to_string
                (Yojson.Basic.Util.member "id_token" t)
            )
          in
          { id_server ; value ; token_type ; id_token ; counter = ref 0 }
        with _ -> raise Bad_JSON_response


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
        (! saved_tokens)

      let remove_saved_token token =
        let value     = value_of_saved_token token     in
        let id_server = id_server_of_saved_token token in
        saved_tokens :=
        (
          remove_from_list
            (fun (x : saved_token) ->
              x.value = value && x.id_server = id_server
            )
            (! saved_tokens)
        )
    end

module Basic
  : (Os_oauth2_client.CLIENT with
      type scope = Basic_scope.scope and
      type saved_token = Basic_ID_token.saved_token
    ) =
  Os_oauth2_client.MakeClient (Basic_scope) (Basic_ID_token)
