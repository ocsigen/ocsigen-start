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

[%%server
exception Error_while_cropping of Unix.process_status
exception Error_while_resizing of Unix.process_status]

let%server resize_image ~src ?(dst = src) ~width ~height =
  let%lwt resize_unix_result =
    Lwt_process.exec
      ( ""
      , [| "convert"
         ; "+repage"
         ; "-strip"
         ; "-interlace"
         ; "Plane"
         ; "-auto-orient"
         ; "-define"
         ; Printf.sprintf "jpeg:size=%dx%d" (2 * width) (2 * height)
         ; "-resize"
         ; Printf.sprintf "%dx%d!" width height
         ; "-quality"
         ; "85"
         ; (* In case of transparent image *)
           "-background"
         ; "white"
         ; "-flatten"
         ; src
         ; "jpg:" ^ dst |] )
  in
  match resize_unix_result with
  | Unix.WEXITED status_code when status_code = 0 -> Lwt.return_unit
  | unix_process_status -> Lwt.fail (Error_while_resizing unix_process_status)

let%server get_image_width file =
  let%lwt width =
    Lwt_process.pread ("", [|"convert"; file; "-print"; "%w"; "/dev/null"|])
  in
  Lwt.return (int_of_string width)

let%server get_image_height file =
  let%lwt height =
    Lwt_process.pread ("", [|"convert"; file; "-print"; "%h"; "/dev/null"|])
  in
  Lwt.return (int_of_string height)

let%server crop_image ~src ?(dst = src) ?ratio ~top ~right ~bottom ~left =
  (* Given arguments are in percent. Use this to convert to pixel. The full size
  is needed to compute the number of pixel *)
  let pixel_of_percent percent full_size_px =
    truncate percent * full_size_px / 100
  in
  let%lwt width_src = get_image_width src in
  let%lwt height_src = get_image_height src in
  let left_px = pixel_of_percent left width_src in
  let top_px = pixel_of_percent top height_src in
  let width_cropped = width_src - left_px - pixel_of_percent right width_src in
  let height_cropped =
    match ratio with
    | None -> height_src - top_px - pixel_of_percent bottom height_src
    | Some ratio -> truncate (float_of_int width_cropped /. ratio)
  in
  let%lwt crop_unix_result =
    Lwt_process.exec
      ( ""
      , [| "convert"
         ; "-crop"
         ; Printf.sprintf "%dx%d+%d+%d" width_cropped height_cropped left_px
             top_px
         ; src
         ; dst |] )
  in
  match crop_unix_result with
  | Unix.WEXITED status_code when status_code = 0 ->
      resize_image ~src:dst ~dst ~width:width_cropped ~height:height_cropped
  | unix_process_status -> Lwt.fail (Error_while_cropping unix_process_status)

let%server record_image directory ?ratio ?cropping file =
  let make_file_saver cp () =
    let new_filename () =
      Ocsigen_lib.make_cryptographic_safe_string ()
      |> String.map (function '+' -> '-' | '/' -> '_' | c -> c)
    in
    fun file_info ->
      let fname = new_filename () in
      let fpath = directory ^ "/" ^ fname in
      let%lwt () = cp (Eliom_request_info.get_tmp_filename file_info) fpath in
      Lwt.return fname
  in
  let cp =
    match cropping with
    | Some (top, right, bottom, left) ->
        fun src dst -> crop_image ~src ~dst ?ratio ~top ~right ~bottom ~left
    | None -> Lwt_unix.link
  in
  let file_saver = make_file_saver cp () in
  file_saver file
