
# Module `Os_fcm_notif.Response`

```ocaml
module Results : sig ... end
```
```ocaml
type t
```
The type representing a FCM response

```ocaml
val multicast_id_of_t : t -> string
```
`multicast_id_of_t response` returns the unique ID identifying the multicast message.

NOTE: In FCM documentation, it is defined as a number but the ID is sometimes too big to be considered as an OCaml integer.

```ocaml
val success_of_t : t -> int
```
`success_of_t response` returns the number of messages that were processed without an error.

```ocaml
val failure_of_t : t -> int
```
`failure_of_t response` returns the number of messages that could not be processed.

```ocaml
val canonical_ids_of_t : t -> int
```
`canonical_ids_of_t response` returns the number of results that contain a canonical registration token. See https://developers.google.com/cloud-messaging/registration\#canonical-ids for more discussion of this topic.

```ocaml
val results_of_t : t -> Results.t list
```
`results_of_t response` returns the status of the messages processed.
