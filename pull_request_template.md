WARNING!

Did you update the template to your changes in library?

To test the template:

eliom-distillery -template os.pgocaml -name test
cd test
make db-init
make db-create
make db-schema
make test.byte (or test.opt)
