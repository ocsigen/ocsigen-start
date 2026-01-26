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

open%shared Eliom_content.Html.F
open%client Js_of_ocaml

[%%shared
exception Predicate_failed of exn option

type content =
  { html_attrs : Html_types.html_attrib Eliom_content.Html.attrib list
  ; title : string option
  ; head : Html_types.head_content_fun elt list
  ; body_attrs : Html_types.body_attrib Eliom_content.Html.attrib list
  ; body : Html_types.body_content elt list }]

let%shared content ?(html_a = []) ?(a = []) ?title ?(head = []) body =
  let html_attrs =
    if Eliom_client.is_client_app ()
    then a_class ["os-client-app"] :: html_a
    else html_a
  in
  { html_attrs
  ; title
  ; head :> Html_types.head_content_fun elt list
  ; body_attrs = a
  ; body :> Html_types.body_content elt list }

[%%shared
module type PAGE = sig
  val title : string
  val js : string list list
  val local_js : string list list
  val css : string list list
  val local_css : string list list
  val other_head : Html_types.head_content_fun Eliom_content.Html.elt list
  val default_error_page : 'a -> 'b -> exn -> content

  val default_connected_error_page :
     Os_types.User.id option
    -> 'a
    -> 'b
    -> exn
    -> content

  val default_predicate : 'a -> 'b -> bool
  val default_connected_predicate : Os_types.User.id option -> 'a -> 'b -> bool
end

module Default_config = struct
  let title = ""
  let js : string list list = []
  let css : string list list = []
  let local_js : string list list = []
  let local_css : string list list = []
  let other_head : Html_types.head_content_fun Eliom_content.Html.elt list = []

  let err_page exn =
    let de =
      if ~%(Ocsigen_config.get_debugmode ())
      then [p [txt "Debug info: "; em [txt (Printexc.to_string exn)]]]
      else []
    in
    let l =
      match exn with
      | Os_session.Not_connected ->
          p [txt "You must be connected to see this page."] :: de
      | _ -> de
    in
    content [div ~a:[a_class ["errormsg"]] (h2 [txt "Error"] :: l)]

  let default_predicate _ _ = true
  let default_connected_predicate _ _ _ = true
  let default_error_page _ _ exn = err_page exn
  let default_connected_error_page _ _ _ exn = err_page exn
end

module Make (C : PAGE) = struct
  let css = List.map (fun cssname -> "css" :: cssname) C.css
  let js = List.map (fun jsname -> "js" :: jsname) C.js

  (* Local assets always have relative links. *)
  let local_css =
    List.map
      (fun cssname ->
         Eliom_content.Html.F.css_link
           ~uri:
             (make_uri ~absolute:false
                ~service:(Eliom_service.static_dir ())
                ("css" :: cssname))
           ())
      C.local_css

  let local_js =
    List.map
      (fun cssname ->
         Eliom_content.Html.F.js_script
           ~a:[a_defer ()]
           ~uri:
             (make_uri ~absolute:false
                ~service:(Eliom_service.static_dir ())
                ("js" :: cssname))
           ())
      C.local_js

  let make_page content =
    let title = match content.title with Some t -> t | None -> C.title in
    let connected_attr =
      if Os_current_user.Opt.get_current_userid () <> None
      then a_class ["os-connected"]
      else a_class ["os-not-connected"]
    in
    let platform_attr =
      a_onload
        [%client
          fun _ : unit ->
            let platform =
              Js.string (Os_platform.css_class (Os_platform.get ()))
            in
            Dom_html.document##.documentElement##.classList##add platform]
    in
    html ~a:content.html_attrs
      (Eliom_tools.F.head ~title ~css ~js
         ~other:(local_css @ local_js @ content.head @ C.other_head)
         ())
      (body
         ~a:(platform_attr :: connected_attr :: content.body_attrs)
         content.body)

  let page
        ?(predicate = C.default_predicate)
        ?(fallback = C.default_error_page)
        f
        gp
        pp
    =
    let content =
      try
        let b = predicate gp pp in
        if b
        then try f gp pp with exc -> fallback gp pp exc
        else fallback gp pp (Predicate_failed None)
      with exc -> fallback gp pp (Predicate_failed (Some exc))
    in
    make_page content

  let connected_page
        ?allow
        ?deny
        ?(predicate = C.default_connected_predicate)
        ?(fallback = C.default_connected_error_page)
        f
        gp
        pp
    =
    let f_wrapped myid gp pp =
      try
        let b = predicate (Some myid) gp pp in
        if b
        then try f myid gp pp with exc -> fallback (Some myid) gp pp exc
        else raise (Predicate_failed None)
      with
      | Predicate_failed _ as exc -> fallback (Some myid) gp pp exc
      | exc -> fallback (Some myid) gp pp (Predicate_failed (Some exc))
    in
    let content =
      try
        Os_session.connected_fun ?allow ?deny
          ~deny_fun:(fun myid_o ->
            fallback myid_o gp pp Os_session.Permission_denied)
          f_wrapped gp pp
      with Os_session.Not_connected as exc -> fallback None gp pp exc
    in
    make_page content

  module Opt = struct
    let connected_page
          ?allow
          ?deny
          ?(predicate = C.default_connected_predicate)
          ?(fallback = C.default_connected_error_page)
          f
          gp
          pp
      =
      let f_wrapped (myid_o : Os_types.User.id option) gp pp =
        try
          let b = predicate myid_o gp pp in
          if b
          then try f myid_o gp pp with exc -> fallback myid_o gp pp exc
          else raise (Predicate_failed None)
        with
        | Predicate_failed _ as exc -> fallback myid_o gp pp exc
        | exc -> fallback myid_o gp pp (Predicate_failed (Some exc))
      in
      let content =
        Os_session.Opt.connected_fun ?allow ?deny
          ~deny_fun:(fun myid_o ->
            fallback myid_o gp pp Os_session.Permission_denied)
          f_wrapped gp pp
      in
      make_page content
  end
end]
