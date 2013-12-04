#!/bin/sh

function usage {
    echo "usage: $0 <template_dir> <template_name>"
    exit 1
}

if [ $# -lt 2 ]; then
    usage
fi

TPL_DIR=$1
TPL_NAME=$2
DEST=$( ocamlfind query eliom )/share/distillery/$TPL_NAME

cp -rf $TPL_DIR $DEST
