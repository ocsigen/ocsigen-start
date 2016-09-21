(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright (C) Université Paris Diderot, CNRS, INRIA, Be Sport.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

(** Time zone and date management for Web applications.

    This module provides some useful functions to detect and manage
    time zones, print dates, etc.

    It's essentially a wrapper to CalendarLib.Calendar.t through an abstract
    type and by using zone and date data provided by the browser.
*)

[%%shared.start]

(** Type representing a local calendar. *)
type local_calendar

(** Convert a local calendar to a UTC calendar *)
val to_utc : local_calendar -> CalendarLib.Calendar.t

(** Convert a calendar to a local calendar. *)
val to_local : CalendarLib.Calendar.t -> local_calendar

val now : unit -> local_calendar

val to_local_time : local_calendar -> CalendarLib.Time.t
val to_local_date : local_calendar -> CalendarLib.Date.t
val local_to_calendar : local_calendar -> CalendarLib.Calendar.t
val local_from_calendar : CalendarLib.Calendar.t -> local_calendar

(** [unknown_timezone ()] returns [true] if the timezone is unknown. Else
    returns [false].
 *)
val unknown_timezone : unit -> bool

(** [smart_time ~now date] returns a smart description of
    [local_date] comparing to [now] (default value of now is the current time
    when the function is called). It does the same job than {!smart_date} but
    « at %hour » is added at the end where %hour is computed from
    {!smart_hours_minutes}.
 *)
val smart_time : ?now:local_calendar -> local_calendar -> string

(** [smart_date ~now local_date] returns a smart description of [local_date]
    comparing to [now] (default value of now is the current time when the
    function is called).
    Smart means
    - if [local_date] is the day before [now], Yesterday is returned.
    - if [local_date] is the same day than [now], Today is returned.
    - if [local_date] is the day after [now], Tomorrow is returned.
    - In the other cases, [now] and [local_date] has the same year,
    it returns the date in the format: %A %B %d where
    - %A is the day name.
    - %B is the month name.
    - %d is day of month.
    Else the year is added at the end.
 *)
val smart_date : ?now:local_calendar -> local_calendar -> string

(** [smart_hours_minutes date] returns the time in the format %I:%M%P where
    - %I is hour in the 12 hours format.
    - %M is minute.
    - %P AM or PM
    If the timezone is unknown, GMT is added.
 *)
val smart_hours_minutes : local_calendar -> string

val smart_interval :
  ?now:local_calendar -> local_calendar -> local_calendar -> string

val smart_date_interval :
  ?now:local_calendar -> local_calendar -> local_calendar -> string


