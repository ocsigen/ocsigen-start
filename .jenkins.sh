opam pin add --no-action eliom-base-app .
opam pin add --no-action ocsigenserver 'https://github.com/ocsigen/ocsigenserver.git#master'
opam pin add --no-action js_of_ocaml 'https://github.com/ocsigen/js_of_ocaml.git#master'
opam pin add --no-action eliom 'https://github.com/ocsigen/eliom.git#master'
opam pin add --no-action ojquery 'https://github.com/ocsigen/ojquery.git#master'
opam pin add --no-action ocsigen-widgets 'https://github.com/ocsigen/ocsigen-widgets.git#master'
opam install --deps-only eliom-base-app
opam install ocsigen-widgets
opam install --verbose eliom-base-app

do_build_doc () {
  make doc
  mkdir -p ${API_DIR}/server ${API_DIR}/client
  cp -Rf doc/client/wiki/*.wiki ${API_DIR}/client
  cp -Rf doc/server/wiki/*.wiki ${API_DIR}/server
  cp -Rf doc/manual-wiki/*.wiki ${MANUAL_SRC_DIR}/
}

do_remove () {
  opam remove --verbose eliom-base-app
}
