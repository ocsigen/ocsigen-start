{shared{

type local_date = private CalendarLib.Calendar.t

val to_utc : local_date -> CalendarLib.Calendar.t
val to_local : CalendarLib.Calendar.t -> local_date

val now : unit -> local_date

val smart_time : ?now:local_date -> local_date -> string
val smart_date : ?now:local_date -> local_date -> string
val smart_hours_minutes : local_date -> string

val smart_interval : ?now:local_date -> local_date -> local_date -> string
val smart_date_interval : ?now:local_date -> local_date -> local_date -> string

}}
