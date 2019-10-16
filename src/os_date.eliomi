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

    It's essentially a wrapper to {!CalendarLib.Calendar.t} through an abstract
    type and by using zone and date data provided by the browser.
    See [calendar] OCaml library for more information about
    [CalendarLib] module. Specifiers from [calendar] OCaml library are used:
    refer you to the official documentation
    (http://calendar.forge.ocamlcore.org/doc) to know the significations.
*)

[%%shared.start]

(** Type representing a local calendar. *)
type local_calendar

[%%server.start]

(** Convert a local calendar to a UTC calendar. Use the client's
    timezone unless the optional [timezone] argument is provided. *)
val to_utc : ?timezone:string -> local_calendar -> CalendarLib.Calendar.t

(** Convert any type of calendar to a local calendar. Use the client's
    timezone unless the optional [timezone] argument is provided.*)
val to_local : ?timezone:string -> CalendarLib.Calendar.t -> local_calendar

(** [now ()] returns the current date as a [local_calendar] value.  Use
    the client's timezone unless the optional [timezone] argument is
    provided.  *)
val now : ?timezone:string -> unit -> local_calendar

[%%client.start]

(** Convert a local calendar to a UTC calendar *)
val to_utc : local_calendar -> CalendarLib.Calendar.t

(** Convert any type of calendar to a local calendar. *)
val to_local : CalendarLib.Calendar.t -> local_calendar

(** [now ()] returns the current date as a [local_calendar] value. *)
val now : unit -> local_calendar

[%%shared.start]

(** [user_tz ()] returns current user's timezone. *)
val user_tz : unit -> string

(** Convert a [local_calendar] value to a [CalendarLib.Time.t] value. *)
val to_local_time : local_calendar -> CalendarLib.Time.t

(** Convert a [local_calendar] value to a [CalendarLib.Date.t] value. *)
val to_local_date : local_calendar -> CalendarLib.Date.t

(** Convert a [local_calendar] value to a [CalendarLib.Calendar.t] value. *)
val local_to_calendar : local_calendar -> CalendarLib.Calendar.t

(** Convert a [CalendarLib.Calendar.t] value to a [local_calendar] value. *)
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
    - if [local_date] is the day before [now], ["Yesterday"] is returned.
    - if [local_date] is the same day than [now], ["Today"] is returned.
    - if [local_date] is the day after [now], ["Tomorrow"] is returned.
    - if [now] and [local_date] has the same year, it returns the date in
      the format: ["%A %B %d"].
    - else the year is added at the end in the same format than the previous
      case.
 *)
val smart_date : ?now:local_calendar -> local_calendar -> string

(** [smart_hours_minutes date] returns the time in the format ["%I:%M%P"].
    If the timezone is unknown, GMT is added.
 *)
val smart_hours_minutes : local_calendar -> string

(** [smart_interval ?now start_date end_date] returns a smart description of
    [start_date] comparing to [end_date] of the year, month, day, hour and
    minutes (compared to {!smart_date_interval}, information about the hour and
    minutes is given).

    The year is not used if [start_date] and [end_date] or if [start_date] and
    [now] have the same year.

    The final output is the concatenation of [smart_start_date] and
    [smart_end_date] with a dash between them.

    [smart_start_date] and [smart_end_date] in in the format ["%B %d, %Y"] if
    year is needed and ["%B %d"] if not.
 *)
val smart_interval :
  ?now:local_calendar -> local_calendar -> local_calendar -> string

(** [smart_date_interval ?now start_date end_date] returns a smart description
    of [start_date] comparing to [end_date] of the year, month and day
    (compared to {!smart_interval}, no information about the hour and
    minutes is given).

    The year is not used if [start_date] and [end_date] or if [start_date] and
    [now] have the same year.

    The final output is the concatenation of [smart_start_date] and
    [smart_end_date] with a dash between them.
    [smart_start_date] (resp. [smart_end_date]) is [start_date] (resp.
    [end_date]) in the format ["%B %d, %Y, %I:%M%P"] if year is needed and ["%B
    %d, %I:%M%P"] if not.
 *)
val smart_date_interval :
  ?now:local_calendar -> local_calendar -> local_calendar -> string
