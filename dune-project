(lang dune 3.18)

(name ocsigen-start)

(generate_opam_files true)

(source
 (github ocsigen/ocsigen-start))

(homepage "https://ocsigen.org/ocsigen-start/")

(authors "dev@ocsigen.org")

(maintainers "dev@ocsigen.org")

(license "LGPL-2.1-only WITH OCaml-LGPL-linking-exception")

(maintenance_intent "(latest)")

(dialect
 (name "eliom-server")
 (implementation
  (extension "eliom"))
 (interface
  (extension "eliomi")))

(package
 (name ocsigen-start)
 (synopsis
  "Higher-level library for developing Web and mobile applications with users, registration, notifications, etc")
 (description
  "Ocsigen Start is a set of higher-level libraries for building client-server Web and mobile applications with Ocsigen (Js_of_ocaml and Eliom).\nIt provides modules for user management (session management, registration, activation keys, ...), managing groups of users, displaying tips, and easily sending notifications to the users.\nOcsigen Start comes with an eliom-distillery template for an app with a database, user management, and session management.\nThis template is intended to serve as a basis for quickly building the Minimum Viable Product for Web and mobile applications with users.\nThe goal is to enable the programmer to concentrate on the core of the app, and not on user management.")
 (depends
  (ocaml
   (>= "4.10"))
  (pgocaml
   (>= "4.0"))
  (pgocaml_ppx
   (>= "4.0"))
  (safepass
   (>= "3.0"))
  (ocsigen-i18n
   (>= "4.0.0"))
  (eliom
   (and
    (>= "12.0.0")
    (< "13.0.0")))
  (ocsigen-toolkit
   (>= "2.7.0"))
  (ocsigen-ppx-rpc
   (>= "1.1"))
  (yojson
   (>= "1.6.0"))
  (resource-pooling
   (and
    (>= "1.0")
    (< "2.0")))
  cohttp-lwt-unix
  (js_of_ocaml
   (>= "6.3.2"))
  (re
   (>= "1.7.2"))
  (ocsipersist-pgsql-config
   (and
    (>= "2.0")
    (< "3.0")))))
