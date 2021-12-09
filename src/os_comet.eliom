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

open%shared Eliom_content.Html
open%shared Eliom_content.Html.F
open%client Js_of_ocaml
open%client Js_of_ocaml_lwt

let%shared __link = () (* to make sure os_comet is linked *)


let%client cookies_enabled () =
  try
    Dom_html.document##.cookie := Js.string "cookietest=1";
    let has_cookies =
      Dom_html.document##.cookie##indexOf (Js.string "cookietest=") <> -1 in
    Dom_html.document##.cookie :=
      Js.string "cookietest=1; expires=Thu, 01-Jan-1970 00:00:01 GMT";
    has_cookies
  with _ ->
    false




let%client restart_process () =
  if Eliom_client.is_client_app () then
    Eliom_client.exit_to ~absolute:false
      ~service:(Eliom_service.static_dir ())
      ["index.html"] ()
  else
    Eliom_client.exit_to ~service:Eliom_service.reload_action () ()


let%client comet_restart_process () =
  (* If cookies do not work,
     the failed comet is probably due to missing cookies.
     In that case we do not restart. This happens for example
     if cookies are deactivated of if the app is running in an iframe
     and the browser forbids third party cookies. *)
  if Eliom_client.is_client_app () || cookies_enabled () then
    restart_process ()

let%client _ = Eliom_comet.set_handle_exn_function
    (fun ?exn () -> comet_restart_process (); Lwt.return_unit)

let%client () = Eliom_client.set_missing_service_handler restart_process
