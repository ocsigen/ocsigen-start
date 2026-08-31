# Module `Os_fcm_notif.Data`

```ocaml
type t
```
The type representing a data payload.

```ocaml
val to_json : t -> Yojson.Safe.t
```
```ocaml
val to_list : t -> (string * Yojson.Safe.t) list
```
`to_list data` returns the representation of the data as a list of tuples `(data_key, json_value)`.

```ocaml
val empty : unit -> t
```
`empty ()` creates an empty data value.

```ocaml
val add_raw_string : string -> string -> t -> t
```
`add_raw_string key content data`

```ocaml
val add_raw_json : string -> Yojson.Safe.t -> t -> t
```
`add_raw_json key content_json data`

```ocaml
module PhoneGap : sig ... end
```
The Cordova plugin phonegap-plugin-push interprets some payloads defined in the data key. The following module defines an interface to these payloads. You can find the payloads list here: https://github.com/phonegap/phonegap-plugin-push/blob/v2.0.x/docs/PAYLOAD.md Be aware that if you use this plugin, all attributes must be added in the data object and not in the notification object which must be empty.
