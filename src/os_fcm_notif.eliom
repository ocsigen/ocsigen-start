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

open Lwt.Syntax

exception FCM_empty_response
exception FCM_no_json_response of string
exception FCM_missing_field of string
exception FCM_unauthorized

module Notification = struct
  (* A notification is represented as a list of pair (key, value) where [key]
   * is the attribute name and [value] the attribute value in the JSON sent to
   * the server.
   *)
  type t = (string * Yojson.Safe.t) list

  let to_json t = `Assoc t
  let empty () = []
  let add_raw_string key str t = (key, `String str) :: t
  let add_raw_json key json t = (key, json) :: t
  let add_title str t = add_raw_string "title" str t
  let add_body str t = add_raw_string "body" str t
  let add_sound str t = add_raw_string "sound" str t
  let add_click_action activity t = add_raw_string "click_action" activity t

  module Ios = struct
    let add_badge nb t = ("badge", `Int nb) :: t
  end

  module Android = struct
    let add_icon icon t = add_raw_string "icon" icon t
    let add_tag tag t = add_raw_string "tag" tag t

    let add_color ~red ~green ~blue t =
      let str_rgb =
        Printf.sprintf "#%X%X%X" (red mod 256) (blue mod 256) (green mod 256)
      in
      add_raw_string "color" str_rgb t
  end
end

module Options = struct
  type t = (string * Yojson.Safe.t) list

  let to_list t = t

  let create ids =
    ["registration_ids", `List (List.map (fun x -> `String x) ids)]

  let add_raw_string key value data = (key, `String value) :: data
  let add_raw_json key value data = (key, value) :: data
  let add_to value t = ("to", `String value) :: t
  let add_condition condition t = ("condition", `String condition) :: t
  let add_collapse_key key t = ("collapse_key", `String key) :: t

  module Priority = struct
    type t = Normal | High
  end

  let add_priority priority t =
    match priority with
    | Priority.Normal -> ("priority", `String "normal") :: t
    | Priority.High -> ("priority", `String "high") :: t

  let add_content_available available t =
    ("content_available", `Bool available) :: t

  let add_time_to_live time_in_seconds t =
    ("time_to_live", `Int time_in_seconds) :: t

  let add_restricted_package_name package_name t =
    ("restricted_package_name", `String package_name) :: t

  let add_dry_run value t = ("dry_run", `Bool value) :: t
end

module Data = struct
  type t = (string * Yojson.Safe.t) list

  let to_list t = t
  let to_json t = `Assoc t
  let empty () = []
  let add_raw_string key value data = (key, `String value) :: data
  let add_raw_json key value data = (key, value) :: data

  module PhoneGap = struct
    let add_message str t = add_raw_string "message" str t
    let add_title str t = add_raw_string "title" str t
    let add_image str t = add_raw_string "image" str t
    let add_soundname str t = add_raw_string "soundname" str t

    let add_notification_channel_id id t =
      ("android_channel_id", `String id) :: t

    let add_notification_id id t = ("notId", `Int id) :: t
    let add_summary_text str t = add_raw_string "summaryText" str t

    module Style = struct
      type t = Inbox | Picture
    end

    let add_style style t =
      let style_to_str =
        match style with Style.Inbox -> "inbox" | Style.Picture -> "picture"
      in
      add_raw_string "style" style_to_str t

    module Action = struct
      type t = Yojson.Safe.t

      let to_json t = t

      let create icon title callback foreground =
        `Assoc
          [ "icon", `String icon
          ; "title", `String title
          ; "callback", `String callback
          ; "foreground", `Bool foreground ]
    end

    let add_actions left right t =
      let actions_list = `List [Action.to_json left; Action.to_json right] in
      ("actions", actions_list) :: t

    let add_led_color a r g b t =
      let json_int_list = `List [`Int a; `Int r; `Int g; `Int b] in
      ("ledColor", json_int_list) :: t

    let add_vibration_pattern pattern t =
      ("vibrationPattern", `List (List.map (fun x -> `Int x) pattern)) :: t

    let add_badge nb t = ("badge", `Int nb) :: t

    module Priority = struct
      type t = Minimum | Low | Default | High | Maximum
    end

    let add_priority priority t =
      let int_of_priority =
        match priority with
        | Priority.Minimum -> -2
        | Priority.Low -> -1
        | Priority.Default -> 0
        | Priority.High -> 1
        | Priority.Maximum -> 2
      in
      ("priority", `Int int_of_priority) :: t

    (** NOTE: we don't add automatically the value picture to style because we
         * don't know if we can mix Inbox and Picture at the same time. In general,
         * a notification with a picture will have a specific ID (we don't want to
         * replace it with another notification) so Inbox value has no sense but we
         * leave the choice to the user.
         *)
    let add_picture picture t = add_raw_string "picture" picture t

    let add_info info t =
      ("info", `String info) :: ("content-available", `Int 1) :: t

    module Visibility = struct
      type t = Secret | Private | Public
    end

    let add_visibility visibility t =
      let visibility_to_int =
        match visibility with
        | Visibility.Secret -> -1
        | Visibility.Private -> 0
        | Visibility.Public -> 1
      in
      ("visibility", `Int visibility_to_int) :: t
  end
end

(* See https://developers.google.com/cloud-messaging/http-server-ref, table 5 *)
module Response = struct
  module Results = struct
    (* If an error occurred, one of these sum types is returned (based on the
           couple (code, error_as_string), see [error_of_string_and_code].
    *)
    type error =
      | Missing_registration
      | Invalid_registration
      | Unregistered_device
      | Invalid_package_name
      | Authentication_failed
      | Mismatch_sender_id
      | Invalid_JSON
      | Message_too_big
      | Invalid_data_key
      | Invalid_time_to_live
      | Timeout
      | Internal_server
      | Device_message_rate_exceeded
      | Topics_message_rate_exceeded
      | Unknown

    (* Internal use. See
           https://developers.google.com/cloud-messaging/http-server-ref
           table 9
    *)
    let error_of_string_and_code = function
      | 200, "MissingRegistration" -> Missing_registration
      | 200, "InvalidRegistration" -> Invalid_registration
      | 200, "NotRegistered" -> Unregistered_device
      | 200, "InvalidPackageName" -> Invalid_package_name
      | 401, _ -> Authentication_failed
      | 200, "MismatchSenderId" -> Mismatch_sender_id
      | 400, _ -> Invalid_JSON
      | 200, "MessageTooBig" -> Message_too_big
      | 200, "InvalidDataKey" -> Invalid_data_key
      | 200, "InvalidTtl" -> Invalid_time_to_live
      | code, "Unavailable" when code = 200 || (500 <= code && code < 600) ->
          Timeout
      | code, "IntervalServerError" when code = 500 || code = 200 ->
          Internal_server
      | 200, "DeviceMessageRateExceeded" -> Device_message_rate_exceeded
      | 200, "TopicsMessageRateExceeded" -> Topics_message_rate_exceeded
      | _ -> Unknown

    let string_of_error = function
      | Missing_registration -> "Missing registration"
      | Invalid_registration -> "Invalid registration"
      | Unregistered_device -> "Unregistered device"
      | Invalid_package_name -> "Invalid package name"
      | Authentication_failed -> "Authentication failed"
      | Mismatch_sender_id -> "Mismatch sender ID"
      | Invalid_JSON -> "Invalid JSON"
      | Message_too_big -> "Message too big"
      | Invalid_data_key -> "Invalid data key"
      | Invalid_time_to_live -> "Invalid time to live"
      | Timeout -> "Timeout"
      | Internal_server -> "Interval server error"
      | Device_message_rate_exceeded -> "Device message rate exceeded"
      | Topics_message_rate_exceeded -> "Topics message rate exceeded"
      | Unknown -> "Unknown"

    (* If no error occurred, the JSON in the results attribute contains a
           mandatory field message_id and an optional field registration_id.
    *)
    type success = {message_id : string; registration_id : string option}

    let message_id_of_success success = success.message_id
    let registration_id_of_success success = success.registration_id

    type t = Success of success | Error of error

    let t_of_json code json =
      let open Yojson.Basic in
      match Util.member "message_id" json with
      (* If the field [message_id] is present, we are in the case of a
               successful message
      *)
      | `String x ->
          let message_id = x in
          let registration_id =
            match Util.member "registration_id" json with
            | `String x -> Some x
            | _ -> None
          in
          Success {message_id; registration_id}
      (* If the field [message_id] is not present, maybe we are in the
               case of an error message.
               The pattern _ is used because is equivalent to `Null in this
               case due to the predefined type of the message_id (string).
      *)
      | _ -> (
        match Util.member "error" json with
        (* If the field [error] is present, we are in the case of an
                 error message.
        *)
        | `String err -> Error (error_of_string_and_code (code, err))
        (* Else we don't know what is the result. *)
        | _ -> raise (FCM_missing_field "No message_id and error fields found.")
        )
  end

  type t =
    { multicast_id : string
    ; success : int
    ; failure : int
    ; canonical_ids : int
    ; results : Results.t list }

  (* Build a type t from the JSON representation of the FCM response. Used
        by [t_of_http_response]. *)
  let t_of_json code json =
    let open Yojson.Basic in
    (* NOTE: In FCM documentation, multicast_id is defined as a number but
           Yojson converts to a string when the number is too big (greater than
           the max integer. The first pattern is `Int x is x is smaller
           than the max integer and the second is `String if x can't be
           interpreted as an integer.
    *)
    let multicast_id =
      match Util.member "multicast_id" json with
      | `Int x -> string_of_int x
      | `String x -> x
      | _ -> raise (FCM_missing_field "Missing multicast_id")
    in
    let success =
      match Util.member "success" json with
      | `Int x -> x
      | _ -> raise (FCM_missing_field "Missing success")
    in
    let failure =
      match Util.member "failure" json with
      | `Int x -> x
      | _ -> raise (FCM_missing_field "Missing failure")
    in
    let canonical_ids =
      match Util.member "canonical_ids" json with
      | `Int x -> x
      | _ -> raise (FCM_missing_field "Missing canonical_ids")
    in
    (* As results is an options array, we don't fail if it's not present but
           we use an empty list.
    *)
    let results =
      match Util.member "results" json with
      | `List l -> List.map (Results.t_of_json code) l
      | _ -> []
    in
    {multicast_id; success; failure; canonical_ids; results}

  (* Build a type t from the raw HTTP response. The HTTP response code is
         computed to pass it to [t_of_json] and to [results_of_json] to be used
         if an error occurred.
  *)
  let t_of_http_response (r, b) =
    Lwt.catch
      (fun () ->
         let status = Cohttp.(Code.code_of_status (Response.status r)) in
         let* b = Cohttp_lwt.Body.to_string b in
         Yojson.Safe.from_string b |> Yojson.Safe.to_basic |> t_of_json status
         |> Lwt.return)
      (function
         (* Could be the case if the server key is wrong or if it's not
           registered only in FCM and not in FCM (since September 2016).
         *)
         | Yojson.Json_error _ ->
             Lwt.fail
               (FCM_no_json_response "It could come from your server key.")
         | exc -> Lwt.reraise exc)

  let multicast_id_of_t response = response.multicast_id
  let success_of_t response = response.success
  let failure_of_t response = response.failure
  let canonical_ids_of_t response = response.canonical_ids
  let results_of_t response = response.results
end

let send server_key notification ?(data = Data.empty ()) options =
  let gcm_url = Uri.of_string "https://fcm.googleapis.com/fcm/send"
  and headers =
    Cohttp.Header.of_list
      ["Authorization", "key=" ^ server_key; "Content-Type", "application/json"]
  (* Data is optional, so we use an option type and a pattern matching *)
  and body =
    `Assoc
      (("notification", Notification.to_json notification)
      :: ("data", Data.to_json data)
      :: Options.to_list options)
    |> Yojson.Safe.to_string |> Cohttp_lwt.Body.of_string
  in
  let* response = Cohttp_lwt_unix.Client.call ~headers ~body `POST gcm_url in
  Response.t_of_http_response response
