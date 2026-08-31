# Module `Os_fcm_notif`

Send push notifications to Android and iOS mobile devices.

This module provides a simple OCaml interface to Firebase Cloud Messaging (FCM) to send push notifications to Android and iOS mobile devices by using downstream HTTP messages in JSON.

You can find all information abou FCM at this address: https://firebase.google.com/docs/cloud-messaging/

Before using this module, you need to register your mobile application in FCM and save the server key FCM will give you. You need to pass this key to [`send`](./#val-send) when you want to send a notification.

On the client, you will need first to register the device on FCM. See

- for iOS: https://firebase.google.com/docs/cloud-messaging/ios/client
- for Android: https://firebase.google.com/docs/cloud-messaging/android/client
If you use this module to send push notifications to mobile devices created with ocsigen-start, you can use one of these plugins.

- cordova-plugin-fcm (binding ocaml-cordova-plugin-fcm).
- phonegap-plugin-push (binding ocaml-cordova-plugin-push-notifications). If you use one of them and if you want to add extra data, you need to use [`Data.add_raw_string`](./Os_fcm_notif-Data.md#val-add_raw_string) or [`Data.add_raw_json`](./Os_fcm_notif-Data.md#val-add_raw_json) depending on the type of the value.
FCM works with tokens which represents a device. This token is used to target the device when you send a notification. The token is retrieved client-side.

To send a notification, you need to use `send server_key notification ?data options` where

- `notification` is of type [`Notification.t`](./Os_fcm_notif-Notification.md#type-t) and represents the notification payload in the JSON sent to FCM.
- `data` is an optional value of type [`Data.t`](./Os_fcm_notif-Data.md#type-t) and represents the data payload in the JSON sent to FCM. By default, it's empty.
- `options` is of type [`Options.t`](./Os_fcm_notif-Options.md#type-t) and represents options in the FCM documentation.
The type [`Options.t`](./Os_fcm_notif-Options.md#type-t) contains the list of registered ID you want to send the notification `notification` to. You can create a value of type [`Options.t`](./Os_fcm_notif-Options.md#type-t) with [`Options.create`](./Os_fcm_notif-Options.md#val-create) which needs a list of client ID. These ID's are the devices you want to send the notification to. You can add some parameters like priorities, restricted package name, condition, etc.

The type [`Notification.t`](./Os_fcm_notif-Notification.md#type-t) contains the notification payloads. The description is given here: https://firebase.google.com/docs/cloud-messaging/http-server-ref

You can create an empty value of type [`Notification.t`](./Os_fcm_notif-Notification.md#type-t) with [`Notification.empty`](./Os_fcm_notif-Notification.md#val-empty). As described in the link given above, you can add a title, a body, etc to the notification. In general, to add the payload `payload`, you can use the function `add_(payload)`. The notification value is at the end to be able to use the pipe. For example, to add a title and a message, you can use: ` <<code language="ocaml" |
      Notification.empty () |>
      add_title "Hello, World!" |>
      add_body "Message to the world!"
    >> `

```ocaml
exception FCM_empty_response
```
```ocaml
exception FCM_no_json_response of string
```
```ocaml
exception FCM_missing_field of string
```
```ocaml
exception FCM_unauthorized
```
```ocaml
module Notification : sig ... end
```
This module provides an interface to create the JSON for the notification key.

```ocaml
module Data : sig ... end
```
```ocaml
module Options : sig ... end
```
```ocaml
module Response : sig ... end
```
```ocaml
val send : 
  string ->
  Notification.t ->
  ?data:Data.t ->
  Options.t ->
  Response.t Lwt.t
```
`send server_key notification options`
