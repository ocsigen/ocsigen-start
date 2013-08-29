#!/bin/sh

for f in $( find . | grep -E "eliom[i]?$" ); do
    tf=$( mktemp XXX )
    sed 's/ol_/eba_/g' $f > $tf
    mv $tf $f
done

for f in $( find . | grep -E "css" ); do
    tf=$( mktemp XXX )
    sed 's/ol_/eba_/g' $f > $tf
    mv $tf $f
done
