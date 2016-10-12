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

(** Send push notifications to mobile clients.

    This module provides a simple OCaml interface to Firebase Cloud Messaging
    (FCM) to send push notifications to mobile devices by using downstream HTTP
    messages in JSON. It is recommended to use
    https://github.com/dannywillems/ocaml-cordova-plugin-push client-side to
    receive push notifications on the mobile.

    This implementation is based on the payloads listed on this page:
    https://github.com/phonegap/phonegap-plugin-push/blob/master/docs/PAYLOAD.md

    Before using this module, you need to register your mobile application in
    FCM and save the server key FCM will give you. You need to pass this key to
    {!send} when you want to send a notification.

    On the client, you will need first to register the device on FCM and save
    server-side the registered ID returned by FCM. You will use this ID when you
    will want to send a notification to the device. This step is described in
    the binding to the Cordova plugin phonegap-plugin-push available at this
    address: https://github.com/dannywillems/ocaml-cordova-plugin-push.
    Don't forget to add the plugin phonegap-plugin-push in the config.xml with
    your sender ID.

    To send a notification, you need to use [send server_key notification
    options] where [notification] is of type {!Notification.t} and [options] is
    of type {!Options.t}.

    The type {!Options.t} contains the list of registered
    ID you want to send the notification [notification] to.
    You can create a value of type {!Options.t} with
    {!Options.create} which needs a list of client ID. These ID's are the
    devices you want to send the notification to.

    The type {!Notification.t} contains the notification payloads. These
    payloads and their description are listed here:
    https://github.com/phonegap/phonegap-plugin-push/blob/master/docs/PAYLOAD.md

    You can create an empty value of type {!Notification.t} with
    {!Notification.empty}. As described in the link given above, you can add a
    title, a message, etc to the notification. In general, to add the payload
    [payload], you can use the function [add_(payload)]. The notification value
    is at the end to be able to use the pipe. For example, to add a title and a
    message, you can use:
    {% <<code language="ocaml" |
      Notification.empty () |>
      add_title "Hello, World!" |>
      add_message "Message to the world!"
    >> %}
*)

exception FCM_empty_response
exception FCM_no_json_response of string
exception FCM_missing_field of string
exception FCM_unauthorized

(** This module provides an interface to create the JSON for the notification
    key
  *)
module Notification :
  sig
    (** The type representing a notification *)
    type t

    val to_json : t -> Yojson.Safe.json

    (** [empty ()] creates an empty notification *)
    val empty : unit -> t

    (** [add_title title notification] adds a title to push notification in
        the notification area. This field is not visible on iOS phones and
        tablets.
     *)
    val add_title : string -> t -> t

    (** [add_body body notification] adds a body to the notification *)
    val add_body : string -> t -> t

    (** [add_sound sound notification] indicates a sound to play when the device
        receives a notification. See
        https://firebase.google.com/docs/cloud-messaging/http-server-ref for
        more information about the value of [sound] depending on the platform.
     *)
    val add_sound : string -> t -> t

    (** [add_click_action activity notification] adds an action when the user
        taps on the notification.
        On Android, the activity [activity] with a matching intent filter is
        launched when user clicks the notification.
        It corresponds to category in the APNs payload.
     *)
    val add_click_action : string -> t -> t

    (* TODO: add_body_loc_key, add_body_loc_args, add_title_loc_args,
     * add_title_loc_key *)

    (** [add_raw_string key content notification] *)
    val add_raw_string : string -> string -> t -> t

    (** [add_raw_json key content_json notification] *)
    val add_raw_json : string -> Yojson.Safe.json -> t -> t

    module Ios :
      sig
        (** [add_badge nb_badge notification] indicates the badge on the client
            app home icon.
         *)
        val add_badge : int -> t -> t
      end

    module Android :
      sig
        (** [add_icon icon notification] indicates notification icon. Sets value
            to [myicon] for drawable resource [myicon].
         *)
        val add_icon : string -> t -> t

        (** [add_tag tag notification] indicates whether each notification
            results in a new entry in the notification drawer on Android.
         *)
        val add_tag : string -> t -> t

        (** [add_color ~red ~green ~blue notification] indicates color of the icon,
            expressed in #rrggbb format.

            Positive values are used modulo 256 i.e. [add_color 257 100 257
            notification] is equivalent to [add_color 1 100 1].
            NOTE: Don't use negative number.
         *)
        val add_color : red:int -> green:int -> blue:int -> t -> t
      end
  end

module Data :
  sig
    (** The type representing a data payload. *)
    type t

    (** [to_list data] returns the representation of the data as a list of
        tuples [(data_key, json_value)]. *)
    val to_list : t -> (string * Yojson.Safe.json) list

    (** [empty ()] creates an empty data value. *)
    val empty : unit -> t

    (** [add_raw_string key content data] *)
    val add_raw_string : string -> string -> t -> t

    (** [add_raw_json key content_json data] *)
    val add_raw_json : string -> Yojson.Safe.json -> t -> t
  end

module Options :
  sig
    (** The type representing an option. *)
    type t

    (** [to_list option] returns the representation of the options as a list of
        tuples [(option_name, json_value)]. *)
    val to_list : t -> (string * Yojson.Safe.json) list

    (** [create registered_ids] creates a new option where [registered_ids] is
        the ID of mobile devices you want to send the notifications to. *)
    val create : string list -> t

    (** [add_to to options] specifies the recipient of a message.

        The value must be a registration token, notification key, or topic. Do
        not set this field when sending to multiple topics.
     *)
    val add_to : string -> t -> t

    (** [add_condition condition options] specifies a logical expression of
        conditions that determine the message target.
     *)
    val add_condition : string -> t -> t

    (** [add_collapse_key collapse_key options] identifies a group of
        messages (e.g., with collapse_key: "Updates Available") that can be
        collapsed, so that only the last message gets sent when delivery can be
        resumed.
     *)
    val add_collapse_key : string -> t -> t

    (** This modules defines a type for priorities for the notifications. See
        https://firebase.google.com/docs/cloud-messaging/concept-options#setting-the-priority-of-a-message
     *)
    module Priority :
      sig
        (** Priority of the message. On iOS, [Normal] means 5 and [High] means
            10.
          *)
        type t = Normal | High
      end

    (** [add_priority priority options] sets the priority of the message. *)
    val add_priority : Priority.t -> t -> t

    (** [add_content_available value options]. On iOS, if [value] is set to
        [true], an inactive client app is awoken. On Android, data messages wake
        the app by default.
     *)
    val add_content_available : bool -> t -> t

    (** [add_time_to_live time_in_seconds options] specifies how long (in
        seconds) the message should be kept in FCM storage if the device is
        offline.
     *)
    val add_time_to_live : int -> t -> t

    (** [add_restricted_package_name package_name options] specifies the
        package name of the application where the registration tokens must match
        in order to receive the message.
     *)
    val add_restricted_package_name : string -> t -> t

    (** [add_dry_run value options]. When set to [true], allows developers to
        test a request without actually sending a message. Default is [false].
     *)
    val add_dry_run : bool -> t -> t
  end

module Response :
  sig
    module Results :
      sig
        (** The type representing a success result.
            If no error occured, the JSON in the results attribute contains a
            mandatory field [message_id] and an optional field
            [registration_id].
         *)
        type success

        (** [message_id_of_success success] returns a string specifying a unique
            ID for each successfully processed message. *)
        val message_id_of_success : success -> string

        (** [registration_id_of_t result] returns a string specifying the
            canonical registration token for the client app that the message was
            processed and sent to.
            A value will be returned by FCM if the registration ID of the device
            you sent the notification to has changed. The value will be the new
            registration ID and must be used to send new notifications. If you
            don't change the ID, you will receive the error NotRegistered.
          *)
        val registration_id_of_success : success -> string option

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

        val string_of_error : error -> string

        (** The type representing a result. *)
        type t = Success of success | Error of error

      end
    (** The type representing a FCM response *)
    type t

    (** [multicast_id_of_t response] returns the unique ID identifying the
        multicast message.

        NOTE: In FCM documentation, it is defined as a number but the ID is
        sometimes too big to be considered as an OCaml integer.
     *)
    val multicast_id_of_t : t -> string

    (** [success_of_t response] returns the number of messages that were
        processed without an error. *)
    val success_of_t : t -> int

    (** [failure_of_t response] returns the number of messages that could not
        be processed. *)
    val failure_of_t : t -> int

    (** [canonical_ids_of_t response] returns the number of results that contain
        a canonical registration token. See
        https://developers.google.com/cloud-messaging/registration#canonical-ids
        for more discussion of this topic. *)
    val canonical_ids_of_t : t -> int

    (** [results_of_t response] returns the status of the messages processed. *)
    val results_of_t : t -> Results.t list
  end

(** [send server_key notification options]  *)
val send :
  string ->
  Notification.t ->
  ?data:Data.t ->
  Options.t ->
  Response.t Lwt.t
