#!/bin/sh

FILE=$1

ident() {
    echo "%%%$1%%%"
}

sed -e "s/foobar/$(ident PROJECT_NAME)/g"\
    -e "s/Foobar/$(ident MODULE_NAME)/g"\
    $FILE
