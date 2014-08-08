#!/bin/sh

usage() {
    echo "usage: $0 <file> <project_name>"
    exit 1
}

capitalize_first_letter() {
    HEAD=$( echo $1 | head -c 1 | tr 'a-z' 'A-Z' )
    TAIL=$( echo $1 | tail -c +2 )
    echo $HEAD$TAIL
}

if [ $# -lt 2 ]; then
    usage
fi

FILE=$1
PROJECT_NAME=$2

ident() {
    echo "%%%$1%%%"
}

sed -e "s/$PROJECT_NAME/$(ident PROJECT_NAME)/g"\
    -e "s/$( capitalize_first_letter $PROJECT_NAME )/$(ident MODULE_NAME)/g"\
    $FILE
