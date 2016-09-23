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

let%server crop_image ~src ?(dst = src) ?ratio ~top ~right ~bottom ~left =
  (* Magick is not cooperative. We use a preemptive thread *)
  Lwt_preemptive.detach
    (fun () ->
       let img = Magick.read_image ~filename:src in
       let img_height = Magick.get_image_height img in
       let img_width = Magick.get_image_width img in
       let x = truncate left * img_width / 100 in
       let y = truncate top * img_height / 100 in
       let width = img_width - x - (truncate right * img_width / 100) in
       let height = match ratio with
         | None -> img_height - y - (truncate bottom * img_height / 100)
         | Some ratio -> truncate (float_of_int width /. ratio) in
       let () = Magick.Imper.crop img ~x ~y ~width ~height in
       Magick.write_image img ~filename:dst)
    ()

let%server record_image directory ?ratio ?cropping file =
  let make_file_saver cp () =
    let new_filename () =
      Ocsigen_lib.make_cryptographic_safe_string ()
      |> String.map (function '+' -> '-' | '/' -> '_' | c -> c) in
    fun file_info ->
      let fname = new_filename () in
      let fpath = directory ^ "/" ^ fname in
      let%lwt () = cp (Eliom_request_info.get_tmp_filename file_info) fpath in
      Lwt.return fname in
  let cp = match cropping with
    | Some (top, right, bottom, left) ->
      fun src dst -> crop_image ~src ~dst ?ratio ~top ~right ~bottom ~left
    | None -> Lwt_unix.link in
  let file_saver = make_file_saver cp () in
  file_saver file
