  $ ocsigen-dune-rules .
  (rule
   (with-stdout-to a.eliom
    (chdir %{workspace_root}
     (run ocsigen-ppx-client -as-pp -loc-filename %{dep:../a.eliom} --impl -server-cmo %{cmo:../a} %{dep:../a.eliom}))))
  (rule
   (with-stdout-to b.eliom
    (chdir %{workspace_root}
     (run ocsigen-ppx-client -as-pp -loc-filename %{dep:../b.eliom} --impl -server-cmo %{cmo:../b} %{dep:../b.eliom}))))
  (rule
   (with-stdout-to b.eliomi
    (chdir %{workspace_root}
     (run ocsigen-ppx-client -as-pp -loc-filename %{dep:../b.eliomi} --intf %{dep:../b.eliomi}))))
