#!/bin/sh

usage() {
    echo "usage: $0 <template_name>"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

TPL_NAME=$1
DEST=$( ocamlfind query eliom )/share/distillery/$TPL_NAME
if [ -d $DEST ]; then
    echo "$DEST exists."
    rm -rf $DEST
else 
    echo "$DEST: no such directory. Nothing to do."
fi
