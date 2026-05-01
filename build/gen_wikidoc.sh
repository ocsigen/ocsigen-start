#!/bin/sh
# Generate wiki API documentation using eliomdoc + wikidoc plugin.
# Usage: ./build/gen_wikidoc.sh [server|client|all]
#
# Output goes to _build/doc/dev/api/{server,client}/.
# To publish, copy the generated wikis to the matching directories on
# the [wikidoc] branch.

set -e

WIKIDOC_DIR=$(ocamlfind query wikidoc)

gen_doc() {
  SIDE="$1"

  case "$SIDE" in
    server)
      CMI_DIR=_build/default/src/.ocsigen_start_server.objs/byte
      DUNE_DIR=src
      PACKAGES=eliom.server,calendar,ocsigenserver,ocsipersist,pgocaml,pgocaml_ppx,macaddr,yojson,ocsigen-toolkit.server,resource-pooling
      ;;
    client)
      CMI_DIR=_build/default/src/client/.ocsigen_start_client.objs/byte
      DUNE_DIR=src/client
      PACKAGES=eliom.client,calendar,ocsigen-toolkit.client,js_of_ocaml,js_of_ocaml-lwt
      ;;
    *)
      echo "Unknown side: $SIDE"; exit 1
      ;;
  esac

  ELIOMI_DIR=src/Os

  dune build @check 2>/dev/null || true

  INCLUDES=$(dune ocaml dump-dot-merlin "$DUNE_DIR" 2>/dev/null \
    | grep "^B " | sed 's/^B /-I /' | tr '\n' ' ')
  JSOO=$(ocamlfind query js_of_ocaml 2>/dev/null || true)
  [ -n "$JSOO" ] && INCLUDES="$INCLUDES -I $JSOO"

  TMPDIR=$(mktemp -d)
  trap "rm -rf $TMPDIR" EXIT

  echo "Creating module aliases for ocamldoc..."
  for cmi in "$CMI_DIR"/os__*.cmi; do
    [ -f "$cmi" ] || continue
    base=$(basename "$cmi" .cmi)                   # os__Session
    short=$(echo "$base" | sed 's/^os__//')        # Session
    modname=$(echo "${base}" | sed 's/^./\U&/')    # Os__Session
    echo "include ${modname}" > "$TMPDIR/${short}.ml"
  done
  for pass in 1 2 3 4; do
    compiled=0
    for ml in "$TMPDIR"/*.ml; do
      [ -f "$ml" ] || continue
      short=$(basename "$ml" .ml)
      if [ ! -f "$TMPDIR/${short}.cmi" ]; then
        if eval ocamlfind ocamlc -package "$PACKAGES" -c -I "$CMI_DIR" -I "$TMPDIR" $INCLUDES \
          -o "$TMPDIR/${short}.cmo" "$ml" 2>/dev/null; then
          compiled=$((compiled + 1))
        fi
      fi
    done
    [ "$compiled" -eq 0 ] && break
  done
  echo "  total: $(ls "$TMPDIR"/*.cmi 2>/dev/null | wc -l) cmi files"

  SOURCE_FILES=$(ls "$ELIOMI_DIR"/*.eliomi "$ELIOMI_DIR"/*.mli 2>/dev/null)

  OUTDIR=_build/doc/dev/api/$SIDE
  rm -rf "$OUTDIR"
  mkdir -p "$OUTDIR"

  echo "Generating $SIDE wiki documentation..."
  eval eliomdoc -"$SIDE" -ppx \
    -colorize-code -stars -sort \
    -package "$PACKAGES" \
    -I "$TMPDIR" \
    -I "$CMI_DIR" \
    $INCLUDES \
    -i "$WIKIDOC_DIR" \
    -g odoc_wiki.cma \
    -d "$OUTDIR" \
    -subproject "$SIDE" \
    $SOURCE_FILES

  echo "Done: $OUTDIR/"
  echo "  $(ls "$OUTDIR"/*.wiki 2>/dev/null | wc -l) wiki files"
}

case "${1:-all}" in
  server|client) gen_doc "$1" ;;
  all) gen_doc server; gen_doc client ;;
  *) echo "Usage: $0 [server|client|all]"; exit 1 ;;
esac
