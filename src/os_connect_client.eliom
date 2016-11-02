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

exception Bad_JSON_response

exception No_such_saved_token

module type IDTOKEN =
  sig
  type saved_token

  val saved_tokens : saved_token list ref

  val cycle_duration : int

  val number_of_cycle : int

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

  val counter_of_saved_token               :
    saved_token  ->
    int ref

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
  type scope = OpenID | Firstname | Lastname | Email | Unknown

  let default_scopes = [ OpenID ]

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

      let cycle_duration                  = 10

      let number_of_cycle                 = 1

      let id_server_of_saved_token t      = t.id_server

      let value_of_saved_token t          = t.value

      let token_type_of_saved_token t     = t.token_type

      let id_token_of_saved_token t       = t.id_token

      let counter_of_saved_token t        = t.counter

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
