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

(** Send push notifications to Android and iOS mobile devices.

    This module provides a simple OCaml interface to Firebase Cloud Messaging
    (FCM) to send push notifications to Android and iOS mobile devices by using
    downstream HTTP messages in JSON.

    You can find all informations abou FCM at this address:
        https://firebase.google.com/docs/cloud-messaging/

    Before using this module, you need to register your mobile application in
    FCM and save the server key FCM will give you. You need to pass this key to
    {!send} when you want to send a notification.

    On the client, you will need first to register the device on FCM.
    See
    - for iOS: https://firebase.google.com/docs/cloud-messaging/ios/client
    - for Android: https://firebase.google.com/docs/cloud-messaging/android/client

    If you use this module to send push notifications to mobile devices created
    with ocsigen-start, you can use one of these plugins.
    - cordova-plugin-fcm (binding ocaml-cordova-plugin-fcm).
    - phonegap-plugin-push (binding ocaml-cordova-plugin-push-notifications).
    If you use one of them and if you want to add extra data, you need to
    use {!Data.add_raw_string} or {!Data.add_raw_json} depending on the type of
    the value.

    FCM works with tokens which represents a device. This token is used to
    target the device when you send a notification. The token is retrieved
    client-side.

    To send a notification, you need to use
    [send server_key notification ?data options]
    where
    - [notification] is of type {!Notification.t} and represents the
    notification payload in the JSON sent to FCM.
    - [data] is an optional value of type {!Data.t} and represents the data
    payload in the JSON sent to FCM. By default, it's empty.
    - [options] is of type {!Options.t} and represents options in the FCM
    documentation.

    The type {!Options.t} contains the list of registered
    ID you want to send the notification [notification] to.
    You can create a value of type {!Options.t} with
    {!Options.create} which needs a list of client ID. These ID's are the
    devices you want to send the notification to.
    You can add some parameters like priorities, restricted package name,
    condition, etc.

    The type {!Notification.t} contains the notification payloads. The
    description is given here:
    https://firebase.google.com/docs/cloud-messaging/http-server-ref

    You can create an empty value of type {!Notification.t} with
    {!Notification.empty}. As described in the link given above, you can add a
    title, a body, etc to the notification. In general, to add the payload
    [payload], you can use the function [add_(payload)]. The notification value
    is at the end to be able to use the pipe. For example, to add a title and a
    message, you can use:
    {% <<code language="ocaml" |
      Notification.empty () |>
      add_title "Hello, World!" |>
      add_body "Message to the world!"
    >> %}
*)

exception FCM_empty_response
exception FCM_no_json_response of string
exception FCM_missing_field of string
exception FCM_unauthorized

(** This module provides an interface to create the JSON for the notification
    key.
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

        For Android devices, "FCM_PLUGIN_ACTIVITY" is mandatory to open the
        application when the user touchs the notification.
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
            If two notifications has the same tag, the last one will replace the
            first one.
            Two different tags produce two different notifications in the
            notification area.
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

    val to_json : t -> Yojson.Safe.json

    (** [to_list data] returns the representation of the data as a list of
        tuples [(data_key, json_value)]. *)
    val to_list : t -> (string * Yojson.Safe.json) list

    (** [empty ()] creates an empty data value. *)
    val empty : unit -> t

    (** [add_raw_string key content data] *)
    val add_raw_string : string -> string -> t -> t

    (** [add_raw_json key content_json data] *)
    val add_raw_json : string -> Yojson.Safe.json -> t -> t

    (** The Cordova plugin phonegap-plugin-push interprets some payloads defined
        in the data key. The following module defines an interface to these
        payloads.
        You can find the payloads list here:
          https://github.com/phonegap/phonegap-plugin-push/blob/v2.0.x/docs/PAYLOAD.md
        Be aware that if you use this plugin, all attributes must be added in
        the data object and not in the notification object which must be empty.

        Another difference is that by default with the phonegap plugin, a new
        notification replaces the last one, which is not the case for
        cordova-plugin-fcm. See {!add_notification_id} for more information.
     *)
    module PhoneGap :
      sig
        (** Add a message attribute to the notification *)
        val add_message : string -> t -> t

        (** Add a title attribute to the notification *)
        val add_title : string -> t -> t

        (** Add an image to the push notification in the notification area *)
        val add_image : string -> t -> t

        (** Add a soundame when the mobile receives the notification *)
        val add_soundname : string -> t -> t

        (** Add a notification ID. By default, a new notification replaces the
            last one because they have the same ID. By adding a different ID for
            two different notifications, two notifications will be shown in the
            notification area instead of one. If a new notification has the same
            ID as an older one, the new one will replace it. It is useful for
            chats for example.
        *)
        val add_notification_id : int -> t -> t

        val add_notification_channel_id : string -> t -> t

        module Style :
          sig
            type t = Inbox | Picture
          end

        val add_style : Style.t -> t -> t

        (** Add a summary text. *)
        val add_summary_text : string -> t -> t

        module Action :
          sig
            type t

            val to_json : t -> Yojson.Safe.json

            (** [create icon title callback foreground] *)
            (* NOTE: The callback is the function name as string to call when
             * the action is chosen. Be sure you exported the callback before
             * sending the notification (by using
             * [Js.Unsafe.set (Js.Unsafe.global "function name" f)] for example)
             *)
            val create : string -> string -> string -> bool -> t
          end

        (** Add two buttons with an action (created with {!Action.create}). Be
            sure you exported the callback in JavaScript.
         *)
        val add_actions : Action.t -> Action.t -> t -> t

        (** Change the LED color when the notification is received. The
            parameters are in the ARGB format.
         *)
        val add_led_color : int -> int -> int -> int -> t -> t

        (** Add a vibration pattern *)
        val add_vibration_pattern : int list -> t -> t

        (** Add a badge to the icon of the notification in the launcher. Only
            available for some launcher. The integer parameter is the number of
            the badge. For iOS, use [Os_fcm_notif.Notification.Ios.add_badge].
         *)
        val add_badge : int -> t -> t

        module Priority :
          sig
            (** [Maximum] means the notification will be displayed on the screen
                above all views during 2 or 3 seconds. The notification will
                remain available in the notification area.
             *)
            type t = Minimum | Low | Default | High | Maximum
          end

        val add_priority : Priority.t -> t -> t

        (** Add a large picture in the notification (under the title and body).
            Don't forget to set style to the value {!Style.Picture}.
         *)
        val add_picture : string -> t -> t

        (** Add [content-available: 1] also *)
        val add_info : string -> t -> t

        module Visibility :
          sig
            type t = Secret | Private | Public
          end

        (** Add the visibility payload *)
        val add_visibility : Visibility.t -> t -> t
      end
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

        (** Sum type to represent errors. You can use {!string_of_error} to have
            a string representation of the error.
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
        | Unknown of int * string

        (** [string_of_error error] returns a string representation of the
            error [error].
         *)
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
