(** List the content of a directory. Returns qualified paths. Returned path
    doesn't contain [./] if [p] is equal to ["."]. *)
let list_dir p =
  (* Let [Sys_error] escape. *)
  let files = Sys.readdir p in
  (* Sorted for reproducibility. *)
  Array.sort String.compare files;
  let concat_p = if p = "." then Fun.id else Filename.concat p in
  Array.iteri (fun i fname -> files.(i) <- concat_p fname) files;
  Array.to_list files

(** Do not raise. *)
let is_dir p = try Sys.is_directory p with Sys_error _ -> false
