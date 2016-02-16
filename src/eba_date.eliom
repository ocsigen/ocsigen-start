(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
 *
 * Copyright (C) 2014
 *      Séverine Maingaud
 *      Vincent Balat
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

    This module  provides some useful function to detect and manage
    time zones, print dates, etc.

*)

(*VVV Warning: Many improvements could be done.
  For example handling daylight saving times changes porperly,
  etc.
*)

[%%client
   let timezone_offset =
     truncate (-. float ((new%js Js.date_now) ##getTimezoneOffset) /. 60.)
   let tz = CalendarLib.Time_Zone.UTC_Plus timezone_offset
   let user_tz () = tz
]

let user_tz_sr =
  Eliom_reference.Volatile.eref
    ~scope:Eba_session.user_indep_session_scope
    CalendarLib.Time_Zone.UTC
let user_tz_gr =
  Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_group_scope
    CalendarLib.Time_Zone.UTC
(* We use 2 scopes in order to have the timezone set asap:
   - if user connected, we use last tz set by user
   - if not connected but new tab, we use same scope as other tabs
*)

let user_tz () =
  (* We take by default the timezone of the browser (session), if already set *)
  let tz = Eliom_reference.Volatile.get user_tz_sr in
  if tz = CalendarLib.Time_Zone.UTC (* not set *)
  then Eliom_reference.Volatile.get user_tz_gr
  else tz


(* This function is called once by each client process to record on server
   the time zone of the client *)
let init_client_process_time tz =
  let tz = CalendarLib.Time_Zone.UTC_Plus tz in
  let () = Eliom_reference.Volatile.set user_tz_gr tz in
  let () = Eliom_reference.Volatile.set user_tz_sr tz in
  Lwt.return ()

let%server init_time_rpc' = init_client_process_time
let%client init_time_rpc' = ()

let%shared init_time_rpc : (_, unit) server_function =
  server_function ~name:"eba_date.init_time_rpc" [%derive.json: int]
    init_time_rpc'

[%%client

let _ =
(* We wait for the client process to be fully loaded: *)
Eliom_client.onload (fun () ->
  Lwt.async (fun () -> ~%init_time_rpc timezone_offset))

]

[%%shared
open CalendarLib

type local_calendar = CalendarLib.Calendar.t

let to_local date =
  let user_tz = user_tz () in
  CalendarLib.(Time_Zone.on Calendar.from_gmt user_tz date)

let to_utc date =
  let user_tz = user_tz () in
  CalendarLib.(Time_Zone.on Calendar.to_gmt user_tz date)

let now () = to_local (CalendarLib.Calendar.now ())

let to_local_time = CalendarLib.Calendar.to_time
let to_local_date = CalendarLib.Calendar.to_date
let local_to_calendar x = x
let local_from_calendar x = x

let smart_date ?(now = now()) local_date =
  let local_date = Calendar.to_date local_date in
  let today = Calendar.to_date now in
  let p = Date.Period.safe_nb_days (Date.sub local_date today) in
  match p with
  |  0 -> "Today"
  |  1 -> "Tomorrow"
  | -1 -> "Yesterday"
  | _  ->
      let format =
        if Date.year local_date = Date.year today then
          "%A %B %d "
        else
          "%A %B %d, %Y"
      in
      Printer.Date.sprint format local_date

let smart_hours_minutes local_date =
  Printer.Calendar.sprint "%-I:%M%P" local_date

let smart_hours_minutes_fixed local_date =
  Printer.Calendar.sprint "%I:%M%P" local_date

let unknown_timezone () = user_tz () = CalendarLib.Time_Zone.UTC

let smart_hours_minutes date =
  if unknown_timezone () then
    smart_hours_minutes date ^ " GMT"
  else
    smart_hours_minutes date

let smart_time ?now date =
  let d = smart_date ?now date in
  let h = smart_hours_minutes date in
  d ^ " at " ^ h

let smart_date_interval ?(now = now ()) start_date end_date =
  let need_year =
    Calendar.year start_date <> Calendar.year end_date
      ||
    Calendar.year start_date <> Calendar.year now
  in
  let format = if need_year then "%B %d, %Y" else "%B %d" in
  let module Printer = CalendarLib.Printer.Calendar in
  let s = Printer.sprint format start_date in
  let e = Printer.sprint format (Calendar.prev end_date `Second) in
  if s = e then smart_date ~now start_date else s ^ "–" ^ e

let smart_interval ?(now = now ()) start_date end_date =
  let need_year =
    Calendar.year start_date <> Calendar.year end_date
      ||
    Calendar.year start_date <> Calendar.year now
  in
  let need_both_days =
    Date.compare (Calendar.to_date start_date) (Calendar.to_date end_date) <> 0
  in
  let format1 =
    if need_year then
      "%B %d, %Y, %I:%M%P"
    else
      "%B %d, %I:%M%P"
  in
  let format2 = if need_both_days then format1 else "%I:%M%P" in
  let module Printer = CalendarLib.Printer.Calendar in
  let s = Printer.sprint format1 start_date in
  let e = Printer.sprint format2 end_date in
  s ^ "–" ^ e

]
