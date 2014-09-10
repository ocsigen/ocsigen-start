(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
 *
 * Copyright (C) 2014
 *      Charly Chevalier
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
{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

exception Predicate_failed of (exn option)


module type Page = sig
  val title : string
  val js : string list list
  val css : string list list
  val other_head : [ Html5_types.head_content_fun ] Eliom_content.Html5.elt list
  val default_error_page :
    'a -> 'b -> exn ->
    [ Html5_types.body_content ] Eliom_content.Html5.elt list Lwt.t
  val default_connected_error_page :
    int64 option -> 'a -> 'b -> exn ->
    [ Html5_types.body_content ] Eliom_content.Html5.elt list Lwt.t
  val default_predicate : 'a -> 'b -> bool Lwt.t
  val default_connected_predicate : int64 option -> 'a -> 'b -> bool Lwt.t
end

module Make(C : Page) = struct

  let css =
    List.map
      (fun cssname -> ("css"::cssname))
      C.css

  let js =
    List.map
      (fun jsname -> ("js"::jsname))
      C.js

  let page
      ?(predicate = C.default_predicate)
      ?(fallback = C.default_error_page)
      f gp pp =
    lwt content =
      try_lwt
        lwt b = predicate gp pp in
        if b then
          try_lwt f gp pp
          with exc -> fallback gp pp exc
        else fallback gp pp (Predicate_failed None)
      with exc -> fallback gp pp (Predicate_failed (Some exc))
    in
    Lwt.return
      (html
         (Eliom_tools.F.head ~title:C.title ~css ~js ~other:C.other_head ())
         (body content))

  let connected_page
      ?allow ?deny
      ?(predicate = C.default_connected_predicate)
      ?(fallback = C.default_connected_error_page)
      f gp pp =
    let f_wrapped uid gp pp =
      try_lwt
        lwt b = predicate (Some uid) gp pp in
        if b then
          try_lwt f uid gp pp
          with exc -> fallback (Some uid) gp pp exc
        else Lwt.fail (Predicate_failed None)
      with
        | (Predicate_failed _) as exc -> fallback (Some uid) gp pp exc
        | exc -> fallback (Some uid) gp pp (Predicate_failed (Some exc))
    in
    lwt content =
      try_lwt
        Eba_session.connected_fun ?allow ?deny
          ~deny_fun:(fun uid_o ->
            fallback uid_o gp pp Eba_session.Permission_denied)
          f_wrapped gp pp
      with Eba_session.Not_connected as exc -> fallback None gp pp exc
    in
    Lwt.return
      (html
         (Eliom_tools.F.head ~title:C.title ~css ~js ~other:C.other_head ())
         (body content))


  module Opt = struct

    let connected_page
        ?allow ?deny
        ?(predicate = C.default_connected_predicate)
        ?(fallback = C.default_connected_error_page)
        f gp pp =
      let f_wrapped (uid_o : int64 option) gp pp =
        try_lwt
          lwt b = predicate uid_o gp pp in
          if b then
            try_lwt f uid_o gp pp
            with exc -> fallback uid_o gp pp exc
          else Lwt.fail (Predicate_failed None)
        with
          | (Predicate_failed _) as exc -> fallback uid_o gp pp exc
          | exc -> fallback uid_o gp pp (Predicate_failed (Some exc))
      in
      lwt content = Eba_session.Opt.connected_fun
        ?allow ?deny
        ~deny_fun:(fun uid_o ->
          fallback uid_o gp pp Eba_session.Permission_denied)
        f_wrapped gp pp in
      Lwt.return
        (html
           (Eliom_tools.F.head ~title:C.title ~css ~js ~other:C.other_head ())
           (body content))

  end
end
