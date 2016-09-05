(** Send push notifications to mobile clients.

    This modules provides a simple OCaml interface to Google Cloud Messaging
    (GCM) to send push notifications to mobile devices. It is recommended to use
    https://github.com/dannywillems/ocaml-cordova-plugin-push client-side to
    receive push notification on the mobile.

    This implementation is based on the payloads listed on this page:
    https://github.com/phonegap/phonegap-plugin-push/blob/master/docs/PAYLOAD.md

    Before using this module, you need to register your mobile application in
    GCM and save the server key GCM will give you. You need to pass this key to
    the [send server_key notification options] function when you want to send a
    notification.

    On the client, you will need first to register the device on GCM and save
    server-side the registered ID returned by GCM. You will use this ID when you
    will want to send a notification to the device. This step is described in
    the binding to the Cordova plugin phonegap-plugin-push available at this
    address: https://github.com/dannywillems/ocaml-cordova-plugin-push.
    Don't forget to add the plugin phonegap-plugin-push in the config.xml with
    your sender ID.

    To send a notification, you need to use [send server_key notification
    options] where notification is of type Notification.t and options is of type
    Options.t.

    The type Options.t contains the list of registered ID you want to send the
    notification [notification] and an optional attribute [collapse_key] (which
    can be added with Options.add_collapse_key) which allows to collapse
    notifications having the same collapse_key value (it avoids to have 5
    different notifications in the notification area for a chat for example).
    You can create a value of type Options.t with [Options.create ids] where ids
    is a list of client ID. These ID's are the devices you want to send the
    notification to.

    The type Notification.t contains the notification payloads. These payloads
    and their description are listed here:
    https://github.com/phonegap/phonegap-plugin-push/blob/master/docs/PAYLOAD.md
    You can create an empty value of type Notification.t with
    Notification.empty (). As described in the link given above, you can add a
    title, a message, etc to the notification. In general, to add the payload
    [payload], you can use the function [add_(payload) value notification]. The
    notification value is at the end to be able to use the pipe. For example, to
    add a title and a message, you can use:
      Notification.empty () |>
      add_title "Hello, World!" |>
      add_message "Message to the world!"
*)

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

    (** Add a notification ID *)
    val add_notId : string -> t -> t

    val add_style : string -> t -> t

    (** Add a summary text. *)
    val add_summary_text : string -> t -> t

    module Action :
      sig
        type t

        val to_json : t -> Yojson.Safe.json

        (* create [icon] [title] [callback] [foreground] *)
        val create : string -> string -> string -> bool -> t
      end

    val add_actions : Action.t -> Action.t -> t -> t

    val add_led_color : int -> int -> int -> int -> t -> t

    val add_vibration_pattern : int list -> t -> t

    (** Add a badge to the icon of the notification in the launcher. Only
     * available for some launcher. The integer parameter is the number of the
     * badge.
     *)
    val add_badge : int -> t -> t

    module Priority :
      sig
        (* Maximum means the notification will be displayed on the screen above
         * all views during 2 or 3 seconds. The notification still available in
         * the notification area.
         *)
        type t = Minimum | Low | Default | High | Maximum
      end

    val add_priority : Priority.t -> t -> t

    val add_picture : string -> t -> t

    (* Add content-available: 1 also *)
    val add_info : string -> t -> t

    module Visibility :
      sig
        type t = Secret | Private | Public
      end

    val add_visibility : Visibility.t -> t -> t

    (* add_raw_string [key] [content] [notification] *)
    val add_raw_string : string -> string -> t -> t

    (* add_raw_json [key] [content json] [notification] *)
    val add_raw_json : string -> Yojson.Safe.json -> t -> t
  end

module Options :
  sig
    type t

    val to_list : t -> (string * Yojson.Safe.json) list

    val create : string list -> t

    val add_collapse_key : string -> t -> t
  end

(* send [server_key] [notification] [options] *)
val send : string -> Notification.t -> Options.t -> unit Lwt.t
