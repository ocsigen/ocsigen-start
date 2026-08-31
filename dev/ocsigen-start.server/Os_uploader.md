# Module `Os_uploader`

This module defines functions to manipulate images to be uploaded.

```ocaml
exception Error_while_cropping of Unix.process_status
```
Raised if an error occurred while cropping a picture. The corresponding code status is given in parameter.

```ocaml
exception Error_while_resizing of Unix.process_status
```
Raised if an error occurred while resizing a picture. The corresponding code status is given in parameter.

```ocaml
val get_image_height : string -> int Lwt.t
```
Return the height of the given image.

```ocaml
val get_image_width : string -> int Lwt.t
```
Return the width of the given image.

```ocaml
val resize_image : 
  src:string ->
  ?dst:string ->
  width:int ->
  height:int ->
  unit ->
  unit Lwt.t
```
Resize the given image (`src`) and save it to `dst` (default is the source file). If an error occurred, it raises the exception `Error_while_resizing` with the corresponding unix process status.

```ocaml
val crop_image : 
  src:string ->
  ?dst:string ->
  ?ratio:float ->
  top:float ->
  right:float ->
  bottom:float ->
  left:float ->
  unit ->
  unit Lwt.t
```
`crop_image ~src ?dst ?ratio ~top ~right ~bottom ~left` crops the image saved in `src` and saves the result in `dst` (default is the source file). `top`, `right`, `bottom` and `left` are the number of pixels the image must be truncated on the specific side. The `ratio` is used after truncating the image. If an error occurred, it raises the exception `Error_while_resizing` or `Error_while_cropping` with the corresponding unix process status.

```ocaml
val record_image : 
  string ->
  ?ratio:float ->
  ?cropping:(float * float * float * float) ->
  Ocsigen_extensions.file_info ->
  string Lwt.t
```
`record_image directory ?ratio ?cropping:(top, right, bottom, left) file` crops the image like `crop_image` and save it in the directory `directory`. If an error occurred, it raises the exception `Error_while_resizing` or `Error_while_cropping` with the corresponding unix process status.
