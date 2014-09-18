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
DEST0=$DESTDIR/$(eliom-distillery -dir)
DEST=$DEST0/$TPL_NAME

mkdir -p $DEST0
[ -f $DEST ] && mv $DEST $DEST-`date +'%F-%H%M%S'`
cp -rf $TPL_DIR $DEST
