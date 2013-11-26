#!/bin/sh

rm -rf samples.distillery
scripts/2distillery.sh scripts/2var.sh samples
rm -rf $( ocamlfind query eliom)/share/distillery/samples
cp -rf samples.distillery $( ocamlfind query eliom)/share/distillery/samples
