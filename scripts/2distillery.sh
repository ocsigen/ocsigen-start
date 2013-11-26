#!/bin/sh

PROJECT_NAME="foobar"

function usage {
    echo "usage: $0 <script> <dir>"
    exit 1
}

function notice {
    echo "notice: $@"
}

function warning {
    echo "warning: $@"
}

function error {
    echo "error: $@"
    exit 1
}

function backup {
    SUFFIX=$( date +"%Y-%m-%d__%Hh%Mm%Ss" )
    echo $1.$SUFFIX
}

if [ $# -lt 1 ]; then
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

for file in $( find $DIR | cut -d '/' -f 2- ); do
    FILE="$DIR/$file"
    if [ ! -d $FILE ] && [ -f $FILE ] ; then
        DFILE="$( echo $file | sed "s|$PROJECT_NAME|PROJECT_NAME|g" )"
        DFILE="$( echo $DFILE | sed 's|/|!|g' )"
        DFILE="$DEST_DIR/$DFILE"
        echo "$SCRIPT $FILE > $DFILE"
        $SCRIPT $FILE > $DFILE
    fi
done
