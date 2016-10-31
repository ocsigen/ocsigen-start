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

module MakeIDToken (Scope : Os_oauth2_server.SCOPE)
  : (IDTOKEN with type scope = Scope.scope) =
  struct
    type scope = Scope.scope

    let timeout               = 10

    let number_of_timeout     = 1

    type saved_token =
    {
      id_client  : int64 ;
      userid     : int64 ;
      token_type : string ;
      value      : string ;
      id_token   : Jwt.t ;
      scope      : scope list ;
      counter    : int ref ;
      secret_key : string (* Needed to be able to check if the client sent the
      right id_token. This is the key used by HS256 to sign the token. *)
    }

    (* ------- *)
    (* getters *)

    let id_client_of_saved_token s  = s.id_client

    let userid_of_saved_token s     = s.userid

    let token_type_of_saved_token s = s.token_type

    let value_of_saved_token s      = s.value

    let id_client_of_saved_token s  = s.id_client

    let scope_of_saved_token s      = s.scope

    let id_token_of_saved_token s   = s.id_token

    let secret_key_of_saved_token s = s.secret_key

    let counter_of_saved_token s    = s.counter

    (* getters *)
    (* ------- *)

    (** ------------------------------------------ *)
    (** ---------- Function about token ---------- *)

    (* FIXME: We need to set an expiration time to 10 minutes for each token in
    * the list. So the type will be saved_token Eliom_reference.Volatile.eref
    * list and not saved_token list Eliom_reference.Volatile.eref.
    *)
    let saved_tokens : saved_token list ref = ref []

    (** token_exists_by_id_client_and_value [id_client] [value] returns true if
      * there exists a saved token with [id_client] and [value].
      *)
    let token_exists_by_id_client_and_value id_client value =
      List.exists
        (fun x -> x.id_client = id_client && x.value = value)
        (! saved_tokens)

    (** token_exists [saved_token] returns true if [saved_token] exists
      *)
    let token_exists saved_token =
      let id_client   = id_client_of_saved_token saved_token  in
      let value       = value_of_saved_token saved_token      in
      token_exists_by_id_client_and_value id_client value

    let generate_id_token ~id_client ~userid =
      let%lwt (_, _, _, redirect_uri, client_id, _) =
        Os_db.OAuth2_server.registered_client_of_id id_client
      in
      (* FIXME: the userid must be encoded in the sub_user value because it must
       * be unique and the same between all token requests so we can't use a
       * random string different for all token request. But the client must
       * not be able to retrieve the userid from the sub_user value. For the
       * moment we use a b64 on client_id with the userid but of course, it's
       * not very secured.
       *)
      let sub_user =
        B64.encode (client_id ^ (Int64.to_string userid))
      in
      (* NOTE: The secret key is generated randomly and is saved in the
       * saved_token type to be able to check if the token sent by the client is
       * the same than the server generated.
       *)
      let secret_key = Os_oauth2_shared.generate_random_string 128 in
      let header_token =
        Jwt.header_of_algorithm_and_typ
          (Jwt.HS256 secret_key)
          "JWT"
      in
      let current_time = Unix.time () in
      let exp_time = 10. *. 60. in (* NOTE: expiration in 10 minutes *)
      let payload_token =
        let open Jwt in
        empty_payload
        |> add_claim iss redirect_uri
        |> add_claim sub sub_user
        |> add_claim aud client_id
        |> add_claim iat (string_of_float current_time)
        |> add_claim exp (string_of_float (current_time +. exp_time))
      in
      Lwt.return
        ((Jwt.t_of_header_and_payload header_token payload_token), secret_key)

    let generate_token_value () =
      Os_oauth2_shared.generate_random_string Os_oauth2_shared.size_token

    let generate_token ~id_client ~userid ~scope =
      let rec generate_token_if_doesnt_exists id_client =
        let value = generate_token_value () in
        if token_exists_by_id_client_and_value id_client value
        then generate_token_if_doesnt_exists id_client
        else value
      in
      let value = generate_token_if_doesnt_exists id_client in
      let%lwt (id_token, secret_key) = generate_id_token ~id_client ~userid in
      Lwt.return
        {
          id_client ; userid ; value ; token_type = "bearer" ;
          id_token ; scope ; counter = ref 0 ; secret_key
        }

    (* Save a token *)
    let save_token token =
      saved_tokens := (token :: (! saved_tokens))

    (* remove a saved token of type saved_token *)
    let remove_saved_token saved_token =
      let value       = value_of_saved_token saved_token      in
      let id_client   = id_client_of_saved_token saved_token  in
      saved_tokens :=
      (
        Os_oauth2_shared.remove_from_list
          (fun x -> x.value = value && x.id_client = id_client)
          (! saved_tokens)
      )

    (* Search a saved token by id_client and value *)
    let saved_token_of_id_client_and_value id_client value =
      let tokens = ! saved_tokens in
      let rec locale = function
      | [] -> raise No_such_saved_token
      | head::tail ->
          if head.id_client = id_client && head.value = value
          then head
          else locale tail
      in
      locale tokens

    (* List all saved tokens *)
    (* IMPROVEME: list tokens by client OAuth2 id *)
    let list_tokens () = (! saved_tokens)
    let saved_token_to_json saved_token =
      `Assoc
      [
        ("token_type", `String "bearer") ;
        ("token", `String (value_of_saved_token saved_token)) ;
        (
          "id_token",
          `String (Jwt.token_of_t (id_token_of_saved_token saved_token))
        )
        (* FIXME: See fixme for saved_token value. *)
        (* ("expires_in", `Int 3600) ; *)
        (* What about a refresh_token ? *)
        (* ("refresh_token", `String refresh_token) ;*)
      ]

    (** ---------- Function about token ---------- *)
    (** ------------------------------------------ *)
  end

module Basic_scope : Os_oauth2_server.SCOPE =
  struct
  (* --------------------------- *)
  (* ---------- Scope ---------- *)

  type scope = OpenID | Firstname | Lastname | Email | Unknown

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

  (** check_scope_list scope_list returns true if every element in
  * [scope_list] is a available scope value.
  * If the list contains only OpenID or if the list doesn't contain OpenID
  * (mandatory scope in RFC), returns false.
  * If an unknown scope value is in list (represented by Unknown value), returns
  * false.
  *)
  let check_scope_list scope_list =
    if List.length scope_list = 0
    then false
    else if List.length scope_list = 1 && List.hd scope_list = OpenID
    then false
    else if not (List.mem OpenID scope_list)
    then false
    else
      List.for_all
        (fun x -> match x with
          | Unknown -> false
          | _ -> true
        )
        scope_list

  (* ---------- Scope ---------- *)
  (* --------------------------- *)
  end

module Basic_ID_token
  : (IDTOKEN with
    type scope = Basic_scope.scope)
  =
  MakeIDToken (Basic_scope)

module Basic
  : (Os_oauth2_server.SERVER with
    type scope = Basic_scope.scope and
    type saved_token = Basic_ID_token.saved_token
  ) =
  Os_oauth2_server.MakeServer
    (Basic_scope)
    (Basic_ID_token)
