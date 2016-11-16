opam pin add --no-action ocsigenserver 'https://github.com/ocsigen/ocsigenserver.git#master'
opam pin add --no-action reactiveData 'https://github.com/ocsigen/reactiveData.git#master'
opam pin add --no-action eliom 'https://github.com/ocsigen/eliom.git#eliompp'
opam pin add --no-action ocsigen-toolkit 'https://github.com/ocsigen/ocsigen-toolkit.git#master'
opam pin add --no-action wikidoc 'https://github.com/ocsigen/wikidoc.git#master'
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
