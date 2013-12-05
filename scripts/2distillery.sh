#!/bin/sh

PROJECT_NAME="foobar"

usage() {
    echo "usage: $0 <script> <dir>"
    exit 1
}

notice() {
    echo "notice: $@"
}

warning() {
    echo "warning: $@"
}

error() {
    echo "error: $@"
    exit 1
}

backup() {
    SUFFIX=$( date +"%Y-%m-%d__%Hh%Mm%Ss" )
    echo $1.$SUFFIX
}

if [ $# -lt 2 ]; then
    usage
fi

# The directory used for generate the template
SCRIPT=$1
DIR=$2
DEST_DIR=$DIR.distillery

if [ ! -d $DIR ]; then
    error "'$DIR': no such file or directory. Make sur to give a valid directory"
fi

if [ -d $DEST_DIR ]; then
    warning "'$DEST_DIR' exists."
    BAK=$( backup $DEST_DIR )
    notice "create a backup of '$DEST_DIR' into '$BAK'"
    mv $DEST_DIR $BAK
fi

notice "create '$DEST_DIR'"
mkdir -p $DEST_DIR

filter() {
    find $DIR\
         -not -path "*/local*"\
    -and -not -path "*/_server*"\
    -and -not -path "*/_client*"\
    -and -not -path "*/_deps*"\
    -and -not -path "*/trash*"\
    -and -not -name ".*"
}

for file in $( filter | cut -d '/' -f 2- ); do
    FILE="$DIR/$file"
    if [ ! -d $FILE ] && [ -f $FILE ] ; then
        DFILE="$( echo $file | sed "s|$PROJECT_NAME|PROJECT_NAME|g" )"
        DFILE="$( echo $DFILE | sed 's|/|!|g' )"
        DFILE="$DEST_DIR/$DFILE"
        echo "$SCRIPT $FILE > $DFILE"
        $SCRIPT $FILE > $DFILE
    fi
done
