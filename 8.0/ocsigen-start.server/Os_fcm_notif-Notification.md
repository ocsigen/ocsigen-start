
# Module `Os_fcm_notif.Notification`

This module provides an interface to create the JSON for the notification key.

```ocaml
type t
```
The type representing a notification

```ocaml
val to_json : t -> Yojson.Safe.t
```
```ocaml
val empty : unit -> t
```
`empty ()` creates an empty notification

```ocaml
val add_title : string -> t -> t
```
`add_title title notification` adds a title to push notification in the notification area. This field is not visible on iOS phones and tablets.

```ocaml
val add_body : string -> t -> t
```
`add_body body notification` adds a body to the notification

```ocaml
val add_sound : string -> t -> t
```
`add_sound sound notification` indicates a sound to play when the device receives a notification. See https://firebase.google.com/docs/cloud-messaging/http-server-ref for more information about the value of `sound` depending on the platform.

```ocaml
val add_click_action : string -> t -> t
```
`add_click_action activity notification` adds an action when the user taps on the notification. On Android, the activity `activity` with a matching intent filter is launched when user clicks the notification. It corresponds to category in the APNs payload.

For Android devices, "FCM\_PLUGIN\_ACTIVITY" is mandatory to open the application when the user touchs the notification.

```ocaml
val add_raw_string : string -> string -> t -> t
```
`add_raw_string key content notification`

```ocaml
val add_raw_json : string -> Yojson.Safe.t -> t -> t
```
`add_raw_json key content_json notification`

```ocaml
module Ios : sig ... end
```
```ocaml
module Android : sig ... end
```