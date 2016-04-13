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
