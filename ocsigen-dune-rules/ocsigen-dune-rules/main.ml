let run internal_prefix dir =
  (match internal_prefix with
   | Some p -> Gen_rules.extra_ppx_args := ["-internal-prefix"; p]
   | None -> ());
  let files = Utils.list_dir dir in
  let files = List.filter (Fun.negate Utils.is_dir) files in
  Gen_rules.run files

open Cmdliner

let arg_dir =
  let doc = "Directory containing the Eliom modules." in
  Arg.(required & pos 0 (some dir) None & info ~doc ~docv:"DIR" [])

let arg_internal_prefix =
  let doc = "Strip $(docv). wrapper prefix from .cmo type paths (for compiling wrapped libraries)." in
  Arg.(value & opt (some string) None & info ~doc ~docv:"PREFIX" ["internal-prefix"])

let cmd =
  let term = Term.(const run $ arg_internal_prefix $ arg_dir) in
  let doc =
    "Generate dune rules for building an ocsigen application or library."
  in
  let info = Cmd.info "ocsigen-dune-rules" ~version:"%%VERSION%%" ~doc in
  Cmd.v info term

let () = exit (Cmd.eval cmd)
