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

[%%shared
  type uploader = (unit,unit) Ot_picture_uploader.service
]

let%shared upload_pic_link
    ?(a = [])
    ?(content=[pcdata "Change profile picture"])
    ?(crop = Some 1.)
    ?(input :
      Html_types.label_attrib Eliom_content.Html.D.Raw.attrib list
      * Html_types.label_content_fun Eliom_content.Html.D.Raw.elt list
      = [], []
    )
    ?(submit :
      Html_types.button_attrib Eliom_content.Html.D.Raw.attrib list
      * Html_types.button_content_fun Eliom_content.Html.D.Raw.elt list
      = [], [pcdata "Submit"]
    )
    (close : (unit -> unit) Eliom_client_value.t)
    (service : uploader)
    userid =
  let content = (content
                 : Html_types.a_content Eliom_content.Html.D.Raw.elt list) in
  D.Raw.a ~a:( a_onclick [%client (fun ev -> Lwt.async (fun () ->
    ~%close () ;
    let upload ?progress ?cropping file =
      Ot_picture_uploader.ocaml_service_upload
        ?progress ?cropping ~service:~%service ~arg:() file in
    try%lwt ignore @@
      Ot_popup.popup
        ~close_button:[ Ot_icons.F.close () ]
        ~onclose:(fun () ->
          Eliom_client.change_page
            ~service:Eliom_service.reload_action () ())
        (fun close -> Ot_picture_uploader.mk_form
            ~crop:~%crop ~input:~%input ~submit:~%submit
            ~after_submit:close upload) ;
      Lwt.return ()
    with e ->
      Os_msg.msg ~level:`Err "Error while uploading the picture";
      Eliom_lib.debug_exn "%s" e "→ ";
      Lwt.return () ) : _ ) ] :: a) content

let%shared reset_tips_service = Os_tips.reset_tips_service

let%shared reset_tips_link (close : (unit -> unit) Eliom_client_value.t) =
  let l = D.Raw.a [pcdata "See help again from beginning"] in
  ignore [%client (
    Lwt_js_events.(async (fun () ->
      clicks (To_dom.of_element ~%l)
        (fun _ _ ->
           ~%close ();
           Eliom_client.exit_to
             ~service:reset_tips_service
             () ();
           Lwt.return ()
        )));
  : unit)];
  l
