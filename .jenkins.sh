opam pin add --no-action wikidoc 'https://github.com/ocsigen/wikidoc.git#master'
opam pin add --no-action eliom 'https://github.com/ocsigen/eliom.git'
opam pin add --no-action ocsigen-start .

opam install --deps-only ocsigen-start
opam install --verbose ocsigen-start

do_build_doc () {
  make doc
  mkdir -p ${API_DIR}/server ${API_DIR}/client
  cp -Rf doc/client/wiki/*.wiki ${API_DIR}/client
  cp -Rf doc/server/wiki/*.wiki ${API_DIR}/server
  cp -Rf doc/manual-wiki/*.wiki ${MANUAL_SRC_DIR}/
}

do_remove () {
  opam remove --verbose ocsigen-start
}
