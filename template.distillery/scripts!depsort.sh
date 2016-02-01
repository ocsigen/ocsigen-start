#!/bin/sh

print_file_line () {
    LINE=$1
    FILE=$(echo "$LINE" | cut -d : -f 1)
    REST=$(echo "$LINE" | cut -d : -f 2)
    for FILE2 in $REST; do
        echo $FILE2 $FILE
    done
}

while read line; do
    print_file_line "$line"
done < $1 | tsort | grep "^_$2.*$3$" | cut -d / -f 2
