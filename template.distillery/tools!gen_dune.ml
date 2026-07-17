let with_suffixes nm l f =
  List.iter
    (fun suffix ->
       if Filename.check_suffix nm suffix
       then f (Filename.chop_suffix nm suffix))
    l

let handle_file_client nm =
  if Filename.check_suffix nm ".pp.eliom"
  then ()
  else if Filename.check_suffix nm ".pp.eliomi"
  then ()
  else
    with_suffixes nm [".eliom"; ".tsv"] (fun nm ->
      Printf.printf
        "(rule (target %s.ml) (deps ../%s.eliom)\n\  (action\n\    (with-stdout-to %%{target}\n\      (chdir .. (run tools/eliom_ppx_client.exe --as-pp -server-cmo %%{cmo:../%s} --impl %s.eliom)))))\n"
        nm nm nm nm);
  if Filename.check_suffix nm ".eliomi"
  then
    let nm = Filename.chop_suffix nm ".eliomi" in
    Printf.printf
      "(rule (target %s.mli) (deps ../%s.eliomi)\n\  (action\n\    (with-stdout-to %%{target}\n\      (chdir .. (run tools/eliom_ppx_client.exe --as-pp --intf %%{deps})))))\n"
      nm nm

let () =
  let root = Sys.readdir ".." in
  let assets = Sys.readdir "../assets" in
  (* The build directory mirrors the sources but also holds generated files,
     which must not be enumerated or their client rule would be emitted twice:
     - .pp.eliom/.pp.eliomi: preprocessing artifacts;
     - the i18n modules produced from assets/*.tsv (the .tsv already emits the
       rule) and the static config produced from *.eliom.in. *)
  let generated_eliom = Hashtbl.create 16 in
  Array.iter
    (fun nm ->
       if Filename.check_suffix nm ".tsv"
       then Hashtbl.replace generated_eliom (Filename.chop_suffix nm ".tsv") ())
    assets;
  Array.iter
    (fun nm ->
       if Filename.check_suffix nm ".eliom.in"
       then
         Hashtbl.replace generated_eliom (Filename.chop_suffix nm ".eliom.in") ())
    root;
  let is_generated nm =
    Filename.check_suffix nm ".pp.eliom"
    || Filename.check_suffix nm ".pp.eliomi"
    || (Filename.check_suffix nm ".eliom"
       && Hashtbl.mem generated_eliom (Filename.chop_suffix nm ".eliom"))
  in
  Array.concat [root; assets]
  |> Array.to_list |> List.sort compare
  |> List.filter (fun nm -> nm.[0] <> '.')
  |> List.filter (fun nm -> not (is_generated nm))
  |> List.iter handle_file_client
