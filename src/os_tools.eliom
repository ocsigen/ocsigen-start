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
  module Navigation_bar : sig

    val ul_of_elts :
      ?ul_class:string list ->
      (string * (unit, unit, Eliom_service.get, _, _, _, _,
                 _, _, unit, Eliom_service.non_ocaml) Eliom_service.t) list ->
      [>`Ul] Eliom_content.Html.F.elt Lwt.t

  end = struct

    let li_of_elt elt = Eliom_content.Html.F.(
      let text, service = elt in
      li [a ~service [pcdata text] ()]
    )

    let ul_of_elts ?(ul_class = []) elt_list = Eliom_content.Html.F.(
      Lwt.return
      @@ ul ~a:[a_class ul_class]
      @@ List.map li_of_elt elt_list
    )

  end
]


let%shared popup_button
    ~button_name
    ?(button_class = ["os_popup_button"])
    ~(popup_content : (unit -> [< Html_types.div_content ]
    Eliom_content.Html.elt Lwt.t))
    = Eliom_content.Html.D.(
      let button =
        button ~a:[a_class button_class] [pcdata button_name]
      in
      let%lwt popup_content = popup_content () in
      ignore
        [%client
            (Lwt.async (fun () ->
              Lwt_js_events.clicks
                (Eliom_content.Html.To_dom.of_element ~%button)
                (fun _ _ ->
                  let%lwt _ =
                    Ot_popup.popup
                      ~close_button:[Eliom_content.Html.D.pcdata "close"]
                      (fun _ -> Lwt.return ~%popup_content)
                  in
                  Lwt.return ()))
               : _)
        ];
      Lwt.return button
    )

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
        = Eliom_content.Html.D.(
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
        )

  end
]
