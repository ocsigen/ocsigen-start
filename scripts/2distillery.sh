#!/bin/sh

usage() {
    echo "usage: $0 <script> <dir> <project_name>"
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

if [ $# -lt 3 ]; then
    usage
fi

# The directory used for generate the template
SCRIPT=$1

# Automatically remove the '/' at the end
DIR=$( echo $2 | sed 's|/*$||' )
DEST_DIR=$2.distillery

PROJECT_NAME=$3

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

for FILE in $( filter ); do
    if [ ! -d $FILE ] && [ -f $FILE ] ; then
        DEST_FILE="$( echo $FILE | sed "s|$DIR/||" )"
        DEST_FILE="$( echo $DEST_FILE | sed "s|$PROJECT_NAME|PROJECT_NAME|g" )"
        DEST_FILE="$( echo $DEST_FILE | sed 's|/|!|g' )"
        DEST_FILE="$DEST_DIR/$DEST_FILE"
        notice "$SCRIPT $FILE $PROJECT_NAME > $DEST_FILE"
        $SCRIPT $FILE $PROJECT_NAME > $DEST_FILE
    fi
done
