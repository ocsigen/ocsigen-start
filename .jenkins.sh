opam pin add --no-action eliom-base-app .
opam pin add --no-action ocsigenserver 'https://github.com/ocsigen/ocsigenserver.git#master'
opam pin add --no-action js_of_ocaml 'https://github.com/ocsigen/js_of_ocaml.git#master'
opam pin add --no-action eliom 'https://github.com/ocsigen/eliom.git#master'
opam pin add --no-action ojwidgets 'https://github.com/ocsigen/ojwidgets.git#master'
opam pin add --no-action ojquery 'https://github.com/ocsigen/ojquery.git#master'
opam pin add --no-action eliom-base-app 'https://github.com/ocsigen/eliom-base-app.git#master'
opam install --deps-only eliom-base-app
opam install --verbose eliom-base-app
opam remove --verbose eliom-base-app
