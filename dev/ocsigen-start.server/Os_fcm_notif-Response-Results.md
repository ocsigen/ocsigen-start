# Module `Response.Results`

```ocaml
type success
```
The type representing a success result. If no error occurred, the JSON in the results attribute contains a mandatory field `message_id` and an optional field `registration_id`.

```ocaml
val message_id_of_success : success -> string
```
`message_id_of_success success` returns a string specifying a unique ID for each successfully processed message.

```ocaml
val registration_id_of_success : success -> string option
```
`registration_id_of_t result` returns a string specifying the canonical registration token for the client app that the message was processed and sent to. A value will be returned by FCM if the registration ID of the device you sent the notification to has changed. The value will be the new registration ID and must be used to send new notifications. If you don't change the ID, you will receive the error NotRegistered.

```ocaml
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
```
Sum type to represent errors. You can use [`string_of_error`](./#val-string_of_error) to have a string representation of the error.

```ocaml
val string_of_error : error -> string
```
`string_of_error error` returns a string representation of the error `error`.

```ocaml
type t = 
  | Success of success
  | Error of error
```
The type representing a result.
