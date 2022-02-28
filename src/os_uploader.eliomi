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

(** This module defines functions to manipulate images to be uploaded. *)

[%%server.start]

exception Error_while_cropping of Unix.process_status
(** Raised if an error occurred while cropping a picture. The corresponding code status is given in parameter. *)

exception Error_while_resizing of Unix.process_status
(** Raised if an error occurred while resizing a picture. The corresponding code status is given in parameter. *)

val get_image_height : string -> int Lwt.t
(** Return the height of the given image. *)

val get_image_width : string -> int Lwt.t
(** Return the width of the given image. *)

val resize_image
  :  src:string
  -> ?dst:string
  -> width:int
  -> height:int
  -> unit
  -> unit Lwt.t
(** Resize the given image ([src]) and save it to [dst] (default is the source
   file). If an error occurred, it raises the exception [Error_while_resizing]
   with the corresponding unix process status.
*)

val crop_image
  :  src:string
  -> ?dst:string
  -> ?ratio:float
  -> top:float
  -> right:float
  -> bottom:float
  -> left:float
  -> unit
  -> unit Lwt.t
(** [crop_image ~src ?dst ?ratio ~top ~right ~bottom ~left] crops the image
    saved in [src] and saves the result in [dst] (default is the source file).
    [top], [right], [bottom] and [left] are the number of pixels the image must
    be truncated on the specific side. The [ratio] is used after truncating the
    image.
    If an error occurred, it raises the exception [Error_while_resizing] or
    [Error_while_cropping] with the corresponding unix process status.
 *)

val record_image
  :  string
  -> ?ratio:float
  -> ?cropping:float * float * float * float
  -> Ocsigen_extensions.file_info
  -> string Lwt.t
(** [record_image directory ?ratio ?cropping:(top, right, bottom, left) file]
    crops the image like [crop_image] and save it in the directory [directory].
    If an error occurred, it raises the exception [Error_while_resizing] or
    [Error_while_cropping] with the corresponding unix process status.
 *)
