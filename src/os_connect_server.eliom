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

exception No_such_saved_token

module type IDTOKEN =
  sig
    type scope

    type saved_token

    val saved_tokens : saved_token list ref

    val cycle_duration : int

    val number_of_cycle : int

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

    val token_exists              :
      saved_token                 ->
      bool

    val generate_token_value      :
      unit                        ->
      string

    val generate_token            :
      id_client:int64             ->
      userid:int64                ->
      scope:scope list            ->
      saved_token Lwt.t

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

    let cycle_duration        = 10

    let number_of_cycle       = 1

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

    let id_client_of_saved_token s  = s.id_client

    let userid_of_saved_token s     = s.userid

    let token_type_of_saved_token s = s.token_type

    let value_of_saved_token s      = s.value

    let id_client_of_saved_token s  = s.id_client

    let scope_of_saved_token s      = s.scope

    let id_token_of_saved_token s   = s.id_token

    let secret_key_of_saved_token s = s.secret_key

    let counter_of_saved_token s    = s.counter

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
      let exp_time = float_of_int (number_of_cycle * cycle_duration) in
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
        ) ;
        ("expires_in", `Int (cycle_duration * number_of_cycle))
        (* What about a refresh_token ? *)
        (* ("refresh_token", `String refresh_token) ;*)
      ]

    (** ---------- Function about token ---------- *)
    (** ------------------------------------------ *)
  end

module Basic_scope : Os_oauth2_server.SCOPE =
  struct
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
