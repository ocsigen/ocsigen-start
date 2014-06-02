#!/bin/sh

usage() {
    echo "usage: $0 <template_dir> <template_name>"
    exit 1
}

if [ $# -lt 2 ]; then
    usage
fi

TPL_DIR=$1
TPL_NAME=$2
DEST=$DESTDIR/$(eliom-distillery -dir)/$TPL_NAME


cp -rf $TPL_DIR $DEST
