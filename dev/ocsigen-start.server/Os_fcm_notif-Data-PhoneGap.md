# Module `Data.PhoneGap`

The Cordova plugin phonegap-plugin-push interprets some payloads defined in the data key. The following module defines an interface to these payloads. You can find the payloads list here: https://github.com/phonegap/phonegap-plugin-push/blob/v2.0.x/docs/PAYLOAD.md Be aware that if you use this plugin, all attributes must be added in the data object and not in the notification object which must be empty.

Another difference is that by default with the phonegap plugin, a new notification replaces the last one, which is not the case for cordova-plugin-fcm. See `add_notification_id` for more information.

```ocaml
val add_message : string -> t -> t
```
Add a message attribute to the notification

```ocaml
val add_title : string -> t -> t
```
Add a title attribute to the notification

```ocaml
val add_image : string -> t -> t
```
Add an image to the push notification in the notification area

```ocaml
val add_soundname : string -> t -> t
```
Add a soundame when the mobile receives the notification

```ocaml
val add_notification_id : int -> t -> t
```
Add a notification ID. By default, a new notification replaces the last one because they have the same ID. By adding a different ID for two different notifications, two notifications will be shown in the notification area instead of one. If a new notification has the same ID as an older one, the new one will replace it. It is useful for chats for example.

```ocaml
val add_notification_channel_id : string -> t -> t
```
```ocaml
module Style : sig ... end
```
```ocaml
val add_style : Style.t -> t -> t
```
```ocaml
val add_summary_text : string -> t -> t
```
Add a summary text.

```ocaml
module Action : sig ... end
```
```ocaml
val add_actions : Action.t -> Action.t -> t -> t
```
Add two buttons with an action (created with [`Action.create`](./Os_fcm_notif-Data-PhoneGap-Action.md#val-create)). Be sure you exported the callback in JavaScript.

```ocaml
val add_led_color : int -> int -> int -> int -> t -> t
```
Change the LED color when the notification is received. The parameters are in the ARGB format.

```ocaml
val add_vibration_pattern : int list -> t -> t
```
Add a vibration pattern

```ocaml
val add_badge : int -> t -> t
```
Add a badge to the icon of the notification in the launcher. Only available for some launcher. The integer parameter is the number of the badge. For iOS, use `Os_fcm_notif.Notification.Ios.add_badge`.

```ocaml
module Priority : sig ... end
```
```ocaml
val add_priority : Priority.t -> t -> t
```
```ocaml
val add_picture : string -> t -> t
```
Add a large picture in the notification (under the title and body). Don't forget to set style to the value [`Style.t.Picture`](./Os_fcm_notif-Data-PhoneGap-Style.md#type-t.Picture).

```ocaml
val add_info : string -> t -> t
```
Add `content-available: 1` also

```ocaml
module Visibility : sig ... end
```
```ocaml
val add_visibility : Visibility.t -> t -> t
```
Add the visibility payload
