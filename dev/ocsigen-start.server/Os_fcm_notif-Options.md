# Module `Os_fcm_notif.Options`

```ocaml
type t
```
The type representing an option.

```ocaml
val to_list : t -> (string * Yojson.Safe.t) list
```
`to_list option` returns the representation of the options as a list of tuples `(option_name, json_value)`.

```ocaml
val create : string list -> t
```
`create registered_ids` creates a new option where `registered_ids` is the ID of mobile devices you want to send the notifications to.

```ocaml
val add_raw_string : string -> string -> t -> t
```
`add_raw_string key content data`

```ocaml
val add_raw_json : string -> Yojson.Safe.t -> t -> t
```
`add_raw_json key content_json data`

```ocaml
val add_to : string -> t -> t
```
`add_to to options` specifies the recipient of a message.

The value must be a registration token, notification key, or topic. Do not set this field when sending to multiple topics.

```ocaml
val add_condition : string -> t -> t
```
`add_condition condition options` specifies a logical expression of conditions that determine the message target.

```ocaml
val add_collapse_key : string -> t -> t
```
`add_collapse_key collapse_key options` identifies a group of messages (e.g., with collapse\_key: "Updates Available") that can be collapsed, so that only the last message gets sent when delivery can be resumed.

```ocaml
module Priority : sig ... end
```
This modules defines a type for priorities for the notifications. See https://firebase.google.com/docs/cloud-messaging/concept-options\#setting-the-priority-of-a-message

```ocaml
val add_priority : Priority.t -> t -> t
```
`add_priority priority options` sets the priority of the message.

```ocaml
val add_content_available : bool -> t -> t
```
`add_content_available value options`. On iOS, if `value` is set to `true`, an inactive client app is awoken. On Android, data messages wake the app by default.

```ocaml
val add_time_to_live : int -> t -> t
```
`add_time_to_live time_in_seconds options` specifies how long (in seconds) the message should be kept in FCM storage if the device is offline.

```ocaml
val add_restricted_package_name : string -> t -> t
```
`add_restricted_package_name package_name options` specifies the package name of the application where the registration tokens must match in order to receive the message.

```ocaml
val add_dry_run : bool -> t -> t
```
`add_dry_run value options`. When set to `true`, allows developers to test a request without actually sending a message. Default is `false`.
