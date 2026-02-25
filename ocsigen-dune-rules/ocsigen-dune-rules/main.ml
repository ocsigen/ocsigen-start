let run dir =
  let files = Utils.list_dir dir in
  let files = List.filter (Fun.negate Utils.is_dir) files in
  Gen_rules.run files

open Cmdliner

let arg_dir =
  let doc = "Directory containing the Eliom modules." in
  Arg.(required & pos 0 (some dir) None & info ~doc ~docv:"DIR" [])

let cmd =
  let term = Term.(const run $ arg_dir) in
  let doc =
    "Generate dune rules for building an ocsigen application or library."
  in
  let info = Cmd.info "ocsigen-dune-rules" ~version:"%%VERSION%%" ~doc in
  Cmd.v info term

let () = exit (Cmd.eval cmd)
