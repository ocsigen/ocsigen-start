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

[%%shared
   open Eliom_content.Html
   open Eliom_content.Html.F
]


let%shared bind_popup_button
    ?a
    ~button
    ~(popup_content : ((unit -> unit Lwt.t) -> [< Html_types.div_content ]
                         Eliom_content.Html.elt Lwt.t) Eliom_client_value.t)
    ()
  =
  ignore
    [%client
      (Lwt.async (fun () ->
         Lwt_js_events.clicks
           (Eliom_content.Html.To_dom.of_element ~%button)
           (fun _ _ ->
              let%lwt _ =
                Ot_popup.popup
                  ?a:~%a
                  ~close_button:[]
                  ~%popup_content
              in
              Lwt.return ()))
       : _)
    ]

[%%shared
  module Carousel : sig

    val make :
      ?vertical:bool ->
      update:
        [ `Goto of int | `Next | `Prev ] React.event Eliom_client_value.t ->
      change:
        ([ `Goto of int | `Next | `Prev ] -> unit) Eliom_client_value.t ->
      carousel:
        ([< Html_types.div_attrib ] Eliom_content.Html.attrib list
         * [< Html_types.div_content ] Eliom_content.Html.elt list) ->
      ?ribbon:
        ([< Html_types.ul_attrib ] Eliom_content.Html.attrib list
         * [< Html_types.li_content_fun ] Eliom_content.Html.elt list list) ->
      ?previous:
        ([< Html_types.button_attrib ] Eliom_content.Html.attrib list
         * Html_types.button_content Eliom_content.Html.elt list) ->
      ?next:
        ([< Html_types.button_attrib ] Eliom_content.Html.attrib list
         * Html_types.button_content Eliom_content.Html.elt list) ->
      ?bullets:
        ([< Html_types.ul_attrib ] Eliom_content.Html.attrib list
         * [< Html_types.li_content_fun ] Eliom_content.Html.elt list list) ->
      unit ->
      [> Html_types.div ] Eliom_content.Html.elt
      * [> Html_types.div ] Eliom_content.Html.elt option
      * [> Html_types.button ] Eliom_content.Html.elt option
      * [> Html_types.button ] Eliom_content.Html.elt option
      * [> Html_types.ul ] Eliom_content.Html.elt option

  end = struct

    let ( >>= ) x f = match x with
      | Some x ->
        f x
      | _ ->
        None

    let return x = Some x

    let make
        ?(vertical=false)
        ~update
        ~change
        ~carousel
        ?ribbon
        ?previous
        ?next
        ?bullets
        ()
        =
        let a, carousel_content = carousel in
        let length = List.length carousel_content in
        let carousel, pos, size, _ =
          Ot_carousel.make ~a ~update ~vertical carousel_content
        in
        let prev =
          previous >>= fun (a,content) ->
          return @@ Ot_carousel.previous ~a ~change ~pos content
        in
        let next =
          next >>= fun (a,content) ->
          return @@ Ot_carousel.next ~a ~change ~pos ~length ~size content
        in
        let ribbon =
          ribbon >>= fun (a,content) ->
          return @@ Ot_carousel.ribbon ~a ~change ~pos ~size content
        in
        let bullets =
          bullets >>= fun (a,content) ->
          return @@ Ot_carousel.bullets ~a ~change ~pos ~length ~content ()
        in
        carousel, ribbon, prev, next, bullets

  end
]
