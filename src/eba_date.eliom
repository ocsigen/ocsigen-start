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

{shared{

   let longago = CalendarLib.Calendar.lmake ~year:1 ()

   let to_gmt (t, tz) = CalendarLib.(Time_Zone.on Calendar.to_gmt tz t)

   (* SSS:
       do not support a connection during the daylight saving times changes *)

   let tz =
     let open CalendarLib in
     let t = Unix.gettimeofday () in
     let gap = (Unix.localtime t).Unix.tm_hour - (Unix.gmtime t).Unix.tm_hour in
     if gap < -12 then gap + 24 else if gap > 11 then gap - 24 else gap

let _ = CalendarLib.Time_Zone.(change (UTC_Plus tz))

let gmtnow () = CalendarLib.Calendar.to_gmt (CalendarLib.Calendar.now ())

}}

{client{

    let user_tz () = CalendarLib.Time_Zone.UTC_Plus tz
  }}

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
   the time zone of the client, and to get in return the gmt time of the server
   (to compensate a little bit the gap between server and client clock) *)
let init_client_process_time tz =
  let tz = CalendarLib.Time_Zone.UTC_Plus tz in
  let () = Eliom_reference.Volatile.set user_tz_gr tz in
  let () = Eliom_reference.Volatile.set user_tz_sr tz in
  Lwt.return (gmtnow ())

let init_time_rpc =
  server_function
    Json.t<int>
  init_client_process_time


{client{

let gmtnow_client = gmtnow ()

let timediff : CalendarLib.Calendar.Period.t ref =
  ref CalendarLib.Calendar.Period.empty

let _ = Lwt.async (fun () ->
  (* We wait for the client process to be fully loaded: *)
  lwt _ = Lwt_js_events.onload () in
  lwt gmtnow_server = %init_time_rpc tz in
  timediff := CalendarLib.Calendar.sub gmtnow_client gmtnow_server;
  Lwt.return ())

(* The reference is server date: we fix local date to match server date *)
let now () =
  CalendarLib.Calendar.rem
    (CalendarLib.Calendar.now ())
    !timediff

let gmtnow () =
  CalendarLib.Calendar.rem
    (gmtnow ())
    !timediff

let time_now () = CalendarLib.Calendar.to_time (now ())

}}

let now = CalendarLib.Calendar.now

{shared{
open CalendarLib

let smart_date gmtdate =
  let user_tz = user_tz () in
  if user_tz = CalendarLib.Time_Zone.UTC (* means: not set *)
  then Printer.Calendar.sprint "%A %d %B %Y" gmtdate
  else
    let date =
      CalendarLib.(Time_Zone.on Calendar.from_gmt user_tz gmtdate) in
    let date = Calendar.to_date date in
    let today =
      CalendarLib.(Time_Zone.on Calendar.from_gmt user_tz (gmtnow ())) in
    let today = Calendar.to_date today in
    let p = Date.Period.safe_nb_days (Date.sub date today) in
    if p  = 0 then "Today" else
    if p = 1 || p = -1
    then "Yesterday"
    else let format =
      if (Date.year date = Date.year today)
      then "%A %d %B" else "%A %d %B %Y"
      in
      Printer.Date.sprint format date

let hours_minutes gmtdate =
  let user_tz = user_tz () in
  if user_tz = CalendarLib.Time_Zone.UTC (* means: not set *)
  then Printer.Calendar.sprint "%-H:%M GMT" gmtdate
  else
    let date =
      CalendarLib.(Time_Zone.on Calendar.from_gmt user_tz gmtdate) in
    Printer.Calendar.sprint "%-H:%M" date

let smart_time gmtdate =
  let d = smart_date gmtdate in
  let h = hours_minutes gmtdate in
  d^" at "^h

}}
