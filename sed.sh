#!/bin/sh

for f in $( ls -1 *.{eliom*,ml*} ); do
    tf=$( mktemp -t "XXXX" )
    sed 's/Ol_/Eba_/g' $f > $tf
    mv $tf $f
done
