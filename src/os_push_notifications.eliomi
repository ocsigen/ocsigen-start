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

    This module provides a simple OCaml interface to Google Cloud Messaging
    (GCM) to send push notifications to mobile devices. It is recommended to use
    https://github.com/dannywillems/ocaml-cordova-plugin-push client-side to
    receive push notifications on the mobile.

    This implementation is based on the payloads listed on this page:
    https://github.com/phonegap/phonegap-plugin-push/blob/master/docs/PAYLOAD.md

    Before using this module, you need to register your mobile application in
    GCM and save the server key GCM will give you. You need to pass this key to
    {!send} when you want to send a notification.

    On the client, you will need first to register the device on GCM and save
    server-side the registered ID returned by GCM. You will use this ID when you
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

(** This module provides a interface to create notifications and add payloads *)
module Notification :
  sig
    (** The type representing a notification *)
    type t

    val to_json : t -> Yojson.Safe.json

    (** Create an empty notification *)
    val empty : unit -> t

    (** Add a message attribute to the notification *)
    val add_message : string -> t -> t

    (** Add a title attribute to the notification *)
    val add_title : string -> t -> t

    (** Add an image to the push notification in the notification area *)
    val add_image : string -> t -> t

    (** Add a soundame when the mobile receives the notification *)
    val add_soundname : string -> t -> t

    (** Add a notification ID. By default, a new notification replaces the last
        one because they have the same ID. By adding a different ID for two
        different notifications, two notifications will be shown in the
        notification area instead of one. If a new notification has the same ID
        as an older one, the new one will replace it. It is useful for chats for
        example.
     *)
    val add_notification_id : int -> t -> t

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
        (* NOTE: The callback is the function name as string to call when the
         * action is chosen. Be sure you exported the callback before sending
         * the notification (by using
         * [Js.Unsafe.set (Js.Unsafe.global "function name" f)] for example)
         *)
        val create : string -> string -> string -> bool -> t
      end

    (** Add two buttons with an action (created with {!Action.create}). Be sure
        you exported the callback in JavaScript.
     *)
    val add_actions : Action.t -> Action.t -> t -> t

    (** Change the LED color when the notification is received. The parameters
        are in the ARGB format.
     *)
    val add_led_color : int -> int -> int -> int -> t -> t

    (** Add a vibration pattern *)
    val add_vibration_pattern : int list -> t -> t

    (** Add a badge to the icon of the notification in the launcher. Only
        available for some launcher. The integer parameter is the number of the
        badge.
     *)
    val add_badge : int -> t -> t

    module Priority :
      sig
        (** [Maximum] means the notification will be displayed on the screen
            above all views during 2 or 3 seconds. The notification will remain
            available in the notification area.
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

    (** [add_raw_string key content notification] *)
    val add_raw_string : string -> string -> t -> t

    (** [add_raw_json key content_json notification] *)
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

    (** DEPRECATED Use {!add_notification_id} instead. It seems it's only
        working with the payload notification and not data. *)
    val add_collapse_key : string -> t -> t
  end

(** [send server_key notification options]  *)
val send : string -> Notification.t -> Options.t -> unit Lwt.t
