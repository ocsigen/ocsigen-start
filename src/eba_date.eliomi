[%%shared.start]

type local_calendar

val to_utc : local_calendar -> CalendarLib.Calendar.t
val to_local : CalendarLib.Calendar.t -> local_calendar

val now : unit -> local_calendar

val to_local_time : local_calendar -> CalendarLib.Time.t
val to_local_date : local_calendar -> CalendarLib.Date.t
val local_to_calendar : local_calendar -> CalendarLib.Calendar.t
val local_from_calendar : CalendarLib.Calendar.t -> local_calendar

val unknown_timezone : unit -> bool

val smart_time : ?now:local_calendar -> local_calendar -> string
val smart_date : ?now:local_calendar -> local_calendar -> string
val smart_hours_minutes : local_calendar -> string

val smart_interval :
  ?now:local_calendar -> local_calendar -> local_calendar -> string
val smart_date_interval :
  ?now:local_calendar -> local_calendar -> local_calendar -> string


