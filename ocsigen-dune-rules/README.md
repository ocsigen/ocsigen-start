# ocsigen-dune-rules

Generate Dune rules for building a client/server application or library.

## Usage

The following `dune` file builds the client and server parts of your library.
Place it in a directory containing `*.eliom` files.

`lib/dune`:
```dune
(library
 (public_name my_lib.server)
 (name my_lib)
 (modes byte native)
 (wrapped false)
 (preprocess
  (pps
   eliom.ppx.server
   ocsigen-ppx-rpc
   --rpc-raw))
 (libraries eliom.server js_of_ocaml))

(subdir
 client
 (library
  (public_name my_lib.client)
  (name my_lib)
  (modes byte)
  (wrapped false)
  (preprocess
   (pps eliom.ppx.client js_of_ocaml-ppx))
  (libraries eliom.client js_of_ocaml js_of_ocaml-lwt))
 (dynamic_include ../dune.client))

(rule
 (deps
  (glob_files *.eliom)
  (glob_files *.eliomi))
 (action
  (with-stdout-to
   dune.client
   (run ocsigen-dune-rules .))))
```

You must also tell Dune that `*.eliom` files contain source code by adding this to your `dune-project` file:

`dune-project`:
```dune
(dialect
 (name "eliom-server")
 (implementation
  (extension "eliom"))
 (interface
  (extension "eliomi")))
```

See [ocsigen-toolkit](https://github.com/ocsigen/ocsigen-toolkit/tree/master) for a working example.
