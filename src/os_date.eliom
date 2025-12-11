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

    This module  provides some useful function to detect and manage
    time zones, print dates, etc.

*)

open%client Js_of_ocaml

let%client timezone =
  (* Use Intl API if available. Revert to using the time zone offset
     otherwise. *)
  match
    if
      Js.Opt.test Js.Unsafe.global##.Intl
      && Js.Opt.test Js.Unsafe.global##.Intl##.DateTimeFormat
    then
      let f = Js.Unsafe.global##.Intl##DateTimeFormat in
      if Js.Opt.test f##.resolvedOptions
      then
        let o = f##resolvedOptions in
        Js.Opt.to_option o##.timeZone
      else None
    else None
  with
  | Some tz -> Js.to_string tz
  | None ->
      Printf.sprintf "Etc/GMT%+d" ((new%js Js.date_now)##getTimezoneOffset / 60)

let user_tz_sr =
  Eliom_reference.Volatile.eref ~scope:Os_session.user_indep_session_scope None

let user_tz_gr =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.default_group_scope None
(* We use 2 scopes in order to have the timezone set asap:
   - if user connected, we use last tz set by user
   - if not connected but new tab, we use same scope as other tabs
*)

let user_tz_opt () =
  (* We take by default the timezone of the browser (session), if already set *)
  let tz = Eliom_reference.Volatile.get user_tz_sr in
  if tz = None (* not set *)
  then Eliom_reference.Volatile.get user_tz_gr
  else tz

let user_tz () = match user_tz_opt () with None -> "UTC" | Some v -> v
let%client user_tz () = timezone

(* This function is called once by each client process to record on server
   the time zone of the client *)
let initialize tz =
  let tz = Some tz in
  Eliom_reference.Volatile.set user_tz_gr tz;
  Eliom_reference.Volatile.set user_tz_sr tz

(* When the browser is loaded, we init the timezone *)
let%rpc init_time_rpc (tz : string) : unit = initialize tz
let%client auto_init = ref true
let%client disable_auto_init () = auto_init := false

let%client _ =
  (* We wait for the client process to be fully loaded: *)
  Eliom_client.onload (fun () ->
    if !auto_init then Lwt.async (fun () -> init_time_rpc timezone))

[%%shared
open CalendarLib

type local_calendar = CalendarLib.Calendar.t]

(* Same as Unix.mktime when TZ=UTC, but avoid modifying this variable. *)
let timegm =
  let days = [|0; 31; 59; 90; 120; 151; 181; 212; 243; 273; 304; 334|] in
  fun { Unix.tm_year
      ; tm_mon
      ; tm_mday = mday
      ; tm_hour = hour
      ; tm_min = min
      ; tm_sec = sec } ->
    let year = tm_year + 1900 in
    let mon = tm_mon + 1 in
    let r = ((year - 1970) * 365) + days.(mon - 1) in
    let r = r + ((year - 1968) / 4) in
    let r = r - ((year - 1900) / 100) in
    let r = r + ((year - 1600) / 400) in
    let r =
      if mon <= 2 && year mod 4 = 0 && (year mod 100 <> 0 || year mod 400 = 0)
      then r - 1
      else r
    in
    let r = float (r + mday - 1) in
    let r = (24. *. r) +. float hour in
    let r = (60. *. r) +. float min in
    (60. *. r) +. float sec

let set_timezone =
  let current_timezone = ref None in
  fun tz ->
    match !current_timezone with
    | Some tz' when tz = tz' -> ()
    | _ ->
        Unix.putenv "TZ" tz;
        (* Leaks memory... *)
        current_timezone := Some tz

(* To avoid one second errors, we round to the nearest second.
   (The time can be slightly off and [Unix.localtime] round downwards...) *)
let to_unixfloat d = floor (CalendarLib.Calendar.to_unixfloat d +. 0.5)

let to_local ?(timezone = user_tz ()) d =
  set_timezone timezone;
  d |> to_unixfloat |> Unix.localtime |> timegm
  |> CalendarLib.Calendar.from_unixfloat

let to_utc ?(timezone = user_tz ()) d =
  set_timezone timezone;
  d |> to_unixfloat |> Unix.gmtime |> Unix.mktime |> fst
  |> CalendarLib.Calendar.from_unixfloat

let%client to_local d =
  let d = CalendarLib.Calendar.to_unixfloat d in
  let o =
    (new%js Js.date_fromTimeValue (Js.float (d *. 1000.)))##getTimezoneOffset
  in
  CalendarLib.Calendar.from_unixfloat (d -. (float o *. 60.))

let%client to_utc d =
  let d = CalendarLib.Calendar.to_unixfloat d in
  let o =
    (new%js Js.date_fromTimeValue (Js.float (d *. 1000.)))##getTimezoneOffset
  in
  let d' = d +. (float o *. 60.) in
  let o' =
    (new%js Js.date_fromTimeValue (Js.float (d' *. 1000.)))##getTimezoneOffset
  in
  CalendarLib.Calendar.from_unixfloat
    (if o = o'
     then d' (* We guessed the DST status right *)
     else d +. (float o' *. 60.))
(* Assume other DST status *)

let%server now ?timezone () = to_local ?timezone (CalendarLib.Calendar.now ())
let%client now () = to_local (CalendarLib.Calendar.now ())
let%shared to_local_time = CalendarLib.Calendar.to_time
let%shared to_local_date = CalendarLib.Calendar.to_date
let%shared local_to_calendar x = x
let%shared local_from_calendar x = x

let%shared smart_date ?(now = now ()) local_date =
  let local_date = Calendar.to_date local_date in
  let today = Calendar.to_date now in
  let p = Date.Period.safe_nb_days (Date.sub local_date today) in
  match p with
  | 0 -> "Today"
  | 1 -> "Tomorrow"
  | -1 -> "Yesterday"
  | _ ->
      let format =
        if Date.year local_date = Date.year today
        then "%A %B %d "
        else "%A %B %d, %Y"
      in
      Printer.Date.sprint format local_date

let%shared smart_hours_minutes local_date =
  Printer.Calendar.sprint "%-I:%M%P" local_date

let%server unknown_timezone () = user_tz_opt () = None
let%client unknown_timezone () = false

let%shared smart_hours_minutes date =
  if unknown_timezone ()
  then smart_hours_minutes date ^ " GMT"
  else smart_hours_minutes date

let%shared smart_time ?now date =
  let d = smart_date ?now date in
  let h = smart_hours_minutes date in
  d ^ " at " ^ h

let%shared smart_date_interval ?(now = now ()) start_date end_date =
  let need_year =
    Calendar.year start_date <> Calendar.year end_date
    || Calendar.year start_date <> Calendar.year now
  in
  let format = if need_year then "%B %d, %Y" else "%B %d" in
  let module Printer = CalendarLib.Printer.Calendar in
  let s = Printer.sprint format start_date in
  let e = Printer.sprint format (Calendar.prev end_date `Second) in
  if s = e then smart_date ~now start_date else s ^ "–" ^ e

let%shared smart_interval ?(now = now ()) start_date end_date =
  let need_year =
    Calendar.year start_date <> Calendar.year end_date
    || Calendar.year start_date <> Calendar.year now
  in
  let need_both_days =
    Date.compare (Calendar.to_date start_date) (Calendar.to_date end_date) <> 0
  in
  let format1 = if need_year then "%B %d, %Y, %I:%M%P" else "%B %d, %I:%M%P" in
  let format2 = if need_both_days then format1 else "%I:%M%P" in
  let module Printer = CalendarLib.Printer.Calendar in
  let s = Printer.sprint format1 start_date in
  let e = Printer.sprint format2 end_date in
  s ^ "–" ^ e
