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

open%shared Js_of_ocaml

[%%shared
  type t =
  | Android
  | IPhone
  | IPad
  | IPod
  | IWatch
  | BlackBerry
  | Windows
  | Unknown
]

let%shared t_of_string platform = match platform with
  | "Android"    -> Android
  | "iPhone"     -> IPhone
  | "iPad"       -> IPad
  | "iPod"       -> IPod
  | "iWatch"     -> IWatch
  | "Windows"    -> Windows
  | "BlackBerry" -> BlackBerry
  | _            -> Unknown

let%shared string_of_t platform = match platform with
  | Android    -> "Android"
  | IPhone     -> "iPhone"
  | IPad       -> "iPad"
  | IPod       -> "iPod"
  | IWatch     -> "iWatch"
  | Windows    -> "Windows"
  | BlackBerry -> "BlackBerry"
  | Unknown    -> "Unknown"

let%client get () =
  let uA = Dom_html.window##.navigator##.userAgent in
  let has s = uA##indexOf(Js.string s) <> -1 in
  if has "Android"
  then Android
  else if has "iPhone"
  then IPhone
  else if has "iPad"
  then IPad
  else if has "iPod"
  then IPod
  else if has "iWatch"
  then IWatch
  else if has "Windows"
  then Windows
  else if has "BlackBerry"
  then BlackBerry
  else Unknown

let%shared css_class platform = match platform with
  | Android                       -> "os-android"
  | IPhone | IPad | IPod | IWatch -> "os-ios"
  | Windows                       -> "os-windows"
  | BlackBerry                    -> "os-blackberry"
  | Unknown                       -> "os-unknown-platform"
