
##----------------------------------------------------------------------
## DISCLAIMER
##
## This file contains the rules to make an ocsigen package. The project
## is configured through the variables in the file Makefile.options.
##----------------------------------------------------------------------

include Makefile.options

##----------------------------------------------------------------------
##			      Internals

## Required binaries
ELIOMC            := eliomc ${WARNING_FLAGS}
ELIOMOPT          := eliomopt ${WARNING_FLAGS}
JS_OF_ELIOM       := js_of_eliom -ppx ${WARNING_FLAGS}
ELIOMDEP          := eliomdep
OCAMLFIND         := ocamlfind

## Where to put intermediate object files.
## - ELIOM_{SERVER,CLIENT}_DIR must be distinct
## - ELIOM_CLIENT_DIR must not be the local dir.
## - ELIOM_SERVER_DIR could be ".", but you need to
##   remove it from the "clean" rules...
export ELIOM_SERVER_DIR := _server
export ELIOM_CLIENT_DIR := _client
export ELIOM_TYPE_DIR   := _server
export OCAMLFIND_DESTDIR := $(shell $(OCAMLFIND) printconf destdir)

ifeq ($(DEBUG),yes)
  GENERATE_DEBUG ?= -g
endif

ifeq ($(NATIVE),yes)
  OPT_RULE = opt
endif

##----------------------------------------------------------------------
## General

.PHONY: all byte opt doc
all: byte $(OPT_RULE)
byte:: $(LIBDIR)/${PKG_NAME}.server.cma $(LIBDIR)/${PKG_NAME}.client.cma
opt:: $(LIBDIR)/${PKG_NAME}.server.cmxs

rebuild-os-db:
	[ ! -z "$(PGHOST)" ] || exit 1
	(echo '(* GENERATED CODE, DO NOT EDIT! *)'; \
         `ocamlfind query  -format "%d/ppx.exe" pgocaml_ppx` \
		src/os_db.ppx.ml ) > src/os_db.ml

##----------------------------------------------------------------------
## Aux

# Use `eliomdep -sort' only in OCaml>4
# Removing this to make it work with mixed ppx/camlp4:
# ifeq ($(shell ocamlc -version|cut -c1),4)
# eliomdep=$(shell $(ELIOMDEP) $(1) -ppx -sort $(2) $(filter %.eliom %.ml,$(3))))
# else
eliomdep=$(3)
# endif
objs=$(patsubst %.ml,$(1)/%.$(2),$(patsubst %.eliom,$(1)/%.$(2),$(filter %.eliom %.ml,$(3))))
#depsort=$(call objs,$(1),$(2),$(call eliomdep,$(3),$(4),$(5)))
depsort=$(shell ocaml tools/sort_deps.ml .depend -I str $(patsubst %.ml,$(1)/%.$(2),$(patsubst %.eliom,$(1)/%.$(2),$(filter %.eliom %.ml,$(5)))))

$(LIBDIR):
	mkdir $(LIBDIR)

##----------------------------------------------------------------------
## Server side compilation

## make it more elegant ?
SERVER_DIRS     := $(shell echo $(foreach f, $(SERVER_FILES), $(dir $(f))) |  tr ' ' '\n' | sort -u | tr '\n' ' ')
SERVER_DEP_DIRS := ${addprefix -eliom-inc ,${SERVER_DIRS}}
SERVER_INC_DIRS := ${addprefix -I $(ELIOM_SERVER_DIR)/, ${SERVER_DIRS}}

SERVER_INC  := ${addprefix -package ,${SERVER_PACKAGES} ${SERVER_PPX_PACKAGES}}
SERVER_DB_INC  := ${addprefix -package ,${SERVER_DB_PACKAGES} ${SERVER_DB_PPX_PACKAGES}}

${ELIOM_TYPE_DIR}/%.type_mli: %.eliom
	${ELIOMC} -ppx -infer ${SERVER_INC} ${SERVER_INC_DIRS} $<

$(LIBDIR)/$(PKG_NAME).server.cma: $(call objs,$(ELIOM_SERVER_DIR),cmo,$(SERVER_FILES)) | $(LIBDIR)
	${ELIOMC} -a -o $@ $(GENERATE_DEBUG) \
          $(call depsort,$(ELIOM_SERVER_DIR),cmo,-server,$(SERVER_INC),$(SERVER_FILES))

$(LIBDIR)/$(PKG_NAME).server.cmxa: $(call objs,$(ELIOM_SERVER_DIR),cmx,$(SERVER_FILES)) | $(LIBDIR)
	${ELIOMOPT} -a -o $@ $(GENERATE_DEBUG) \
          $(call depsort,$(ELIOM_SERVER_DIR),cmx,-server,$(SERVER_INC),$(SERVER_FILES))

%.cmxs: %.cmxa
	$(ELIOMOPT) -ppx -shared -linkall -o $@ $(GENERATE_DEBUG) $<

${ELIOM_SERVER_DIR}/%_db.cmi: %_db.mli
	${ELIOMC} -ppx -c ${SERVER_DB_INC} ${SERVER_INC_DIRS} $(GENERATE_DEBUG) $<
${ELIOM_SERVER_DIR}/%.cmi: %.mli
	${ELIOMC} -ppx -c ${SERVER_INC} ${SERVER_INC_DIRS} $(GENERATE_DEBUG) $<

${ELIOM_SERVER_DIR}/%.cmi: %.eliomi
	${ELIOMC} -ppx -c ${SERVER_INC} ${SERVER_INC_DIRS} $(GENERATE_DEBUG) $<

${ELIOM_SERVER_DIR}/%_db.cmo: %_db.ml
	${ELIOMC} -ppx -c ${SERVER_DB_INC} ${SERVER_INC_DIRS} $(GENERATE_DEBUG) $<
${ELIOM_SERVER_DIR}/%.cmo: %.ml
	${ELIOMC} -ppx -c ${SERVER_INC} ${SERVER_INC_DIRS} $(GENERATE_DEBUG) $<
${ELIOM_SERVER_DIR}/%.cmo: %.eliom
	${ELIOMC} -ppx -c ${SERVER_INC} ${SERVER_INC_DIRS} $(GENERATE_DEBUG) $<

${ELIOM_SERVER_DIR}/%_db.cmx: %_db.ml
	${ELIOMOPT} -ppx -c ${SERVER_DB_INC} ${SERVER_INC_DIRS} $(GENERATE_DEBUG) $<
${ELIOM_SERVER_DIR}/%.cmx: %.ml
	${ELIOMOPT} -ppx -c ${SERVER_INC} ${SERVER_INC_DIRS} $(GENERATE_DEBUG) $<
${ELIOM_SERVER_DIR}/%.cmx: %.eliom
	${ELIOMOPT} -ppx -c ${SERVER_INC} ${SERVER_INC_DIRS} $(GENERATE_DEBUG) $<


##----------------------------------------------------------------------
## Client side compilation

## make it more elegant ?
CLIENT_DIRS     := $(shell echo $(foreach f, $(CLIENT_FILES), $(dir $(f))) |  tr ' ' '\n' | sort -u | tr '\n' ' ')
CLIENT_DEP_DIRS := ${addprefix -eliom-inc ,${CLIENT_DIRS}}
CLIENT_INC_DIRS := ${addprefix -I $(ELIOM_CLIENT_DIR)/,${CLIENT_DIRS}}

CLIENT_LIBS := ${addprefix -package ,${CLIENT_PACKAGES} ${CLIENT_PPX_PACKAGES}}
CLIENT_INC  := ${addprefix -package ,${CLIENT_PACKAGES} ${CLIENT_PPX_PACKAGES}}

CLIENT_OBJS := $(filter %.eliom %.ml, $(CLIENT_FILES))
CLIENT_OBJS := $(patsubst %.eliom,${ELIOM_CLIENT_DIR}/%.cmo, ${CLIENT_OBJS})
CLIENT_OBJS := $(patsubst %.ml,${ELIOM_CLIENT_DIR}/%.cmo, ${CLIENT_OBJS})

$(LIBDIR)/$(PKG_NAME).client.cma: $(call objs,$(ELIOM_CLIENT_DIR),cmo,$(CLIENT_FILES)) | $(LIBDIR)
	${JS_OF_ELIOM} -a -o $@ $(GENERATE_DEBUG) \
          $(call depsort,$(ELIOM_CLIENT_DIR),cmo,-client,$(CLIENT_INC),$(CLIENT_FILES))

${ELIOM_CLIENT_DIR}/%.cmi: %.mli
	${JS_OF_ELIOM} -c ${CLIENT_INC} ${CLIENT_INC_DIRS} $(GENERATE_DEBUG) $<

${ELIOM_CLIENT_DIR}/%.cmo: %.eliom
	${JS_OF_ELIOM} -c ${CLIENT_INC} ${CLIENT_INC_DIRS} $(GENERATE_DEBUG) $<
${ELIOM_CLIENT_DIR}/%.cmo: %.ml
	${JS_OF_ELIOM} -c ${CLIENT_INC} ${CLIENT_INC_DIRS} $(GENERATE_DEBUG) $<

${ELIOM_CLIENT_DIR}/%.cmi: %.eliomi
	${JS_OF_ELIOM} -c ${CLIENT_INC} ${CLIENT_INC_DIRS} $(GENERATE_DEBUG) $<

##----------------------------------------------------------------------
## Installation

CLIENT_CMO=$(wildcard $(addsuffix /*.cmo,$(addprefix $(ELIOM_CLIENT_DIR)/,$(CLIENT_DIRS))))
CLIENT_CMO_FILENAMES=$(foreach f, $(call depsort,$(ELIOM_CLIENT_DIR),cmo,-client,$(CLIENT_INC),$(CLIENT_FILES)), $(patsubst $(dir $(f))%,%,$(f)))
META: META.in
	sed -e 's#@@PKG_NAME@@#$(PKG_NAME)#g' \
		-e 's#@@PKG_VERS@@#$(PKG_VERS)#g' \
		-e 's#@@PKG_DESC@@#$(PKG_DESC)#g' \
		-e 's#@@CLIENT_REQUIRES@@#$(CLIENT_PACKAGES)#g' \
		-e 's#@@CLIENT_ARCHIVES_BYTE@@#$(CLIENT_CMO_FILENAMES)#g' \
		-e 's#@@SERVER_REQUIRES@@#$(SERVER_PACKAGES) $(SERVER_DB_PACKAGES)#g' \
		-e 's#@@SERVER_ARCHIVES_BYTE@@#$(PKG_NAME).server.cma#g' \
		-e 's#@@SERVER_ARCHIVES_NATIVE@@#$(PKG_NAME).server.cmxa#g' \
		-e 's#@@SERVER_ARCHIVES_NATIVE_PLUGIN@@#$(PKG_NAME).server.cmxs#g' \
		$< > $@

CLIENT_CMI=$(wildcard $(addsuffix /os_*.cmi,$(addprefix $(ELIOM_CLIENT_DIR)/,$(CLIENT_DIRS))))
SERVER_CMI=$(wildcard $(addsuffix /os_*.cmi,$(addprefix $(ELIOM_SERVER_DIR)/,$(SERVER_DIRS))))
SERVER_CMX=$(wildcard $(addsuffix /os_*.cmx,$(addprefix $(ELIOM_SERVER_DIR)/,$(SERVER_DIRS))))
install: all META
	$(OCAMLFIND) install $(PKG_NAME) META
	mkdir -p $(OCAMLFIND_DESTDIR)/$(PKG_NAME)/client
	mkdir -p $(OCAMLFIND_DESTDIR)/$(PKG_NAME)/server
	cp $(CLIENT_CMO) $(OCAMLFIND_DESTDIR)/$(PKG_NAME)/client
	cp $(CLIENT_CMI) $(OCAMLFIND_DESTDIR)/$(PKG_NAME)/client
	cp $(SERVER_CMI) $(OCAMLFIND_DESTDIR)/$(PKG_NAME)/server
	cp $(SERVER_CMX) $(OCAMLFIND_DESTDIR)/$(PKG_NAME)/server
	cp $(LIBDIR)/$(PKG_NAME).client.cma $(OCAMLFIND_DESTDIR)/$(PKG_NAME)/client
	cp $(LIBDIR)/$(PKG_NAME).server.a $(OCAMLFIND_DESTDIR)/$(PKG_NAME)/server
	cp $(LIBDIR)/$(PKG_NAME).server.cm* $(OCAMLFIND_DESTDIR)/$(PKG_NAME)/server
	scripts/install.sh $(TEMPLATE_DIR) $(TEMPLATE_NAME)

##----------------------------------------------------------------------
## Dependencies

DEPSDIR := _deps

ifneq ($(MAKECMDGOALS),distclean)
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(MAKECMDGOALS),depend)
    include .depend
endif
endif
endif

.depend: $(patsubst %,$(DEPSDIR)/%.server,$(SERVER_FILES)) $(patsubst %,$(DEPSDIR)/%.client,$(CLIENT_FILES))
	cat $^ > $@

$(DEPSDIR)/%.server: % | $(DEPSDIR)
	$(ELIOMDEP) -server -ppx $(SERVER_INC) $(SERVER_DEP_DIRS) $< > $@

$(DEPSDIR)/%.client: % | $(DEPSDIR)
	$(ELIOMDEP) -client -ppx $(CLIENT_INC) $(CLIENT_DEP_DIRS) $< > $@

$(DEPSDIR):
	mkdir -p $@
	mkdir -p $(addprefix $@/, ${CLIENT_DIRS})
	mkdir -p $(addprefix $@/, ${SERVER_DIRS})

##----------------------------------------------------------------------
## Generate CSS from SASS in the template.

## A temporary filename and project name are mandatory because SASS files
## contain %%%PROJECT_NAME%%% as ID which is not available in SCSS.
## For the moment, no external SCSS files are used to generate the CSS.

.PHONY: generate_css

generate_css: $(CSS_FILES)

$(TEMPLATE_DIR)/static\!defaultcss\!%.css: $(TEMPLATE_DIR)/sass!%.scss
	sed s/%%%PROJECT_NAME%%%/$(SASS_TEMPORARY_PROJECT_NAME)/g $< > \
        $(SASS_TEMPORARY_FILENAME).scss
	sass $(SASS_TEMPORARY_FILENAME).scss $(SASS_TEMPORARY_FILENAME).css
	sed s/$(SASS_TEMPORARY_PROJECT_NAME)/%%%PROJECT_NAME%%%/g \
        $(SASS_TEMPORARY_FILENAME).css > $@

##----------------------------------------------------------------------
## Documentation

COMMON_OPTIONS := -colorize-code -stars -sort

eliomdoc_wiki = ODOC_WIKI_SUBPROJECT="$(1)" \
                eliomdoc \
                -$(1) \
                -ppx -package pgocaml,yojson,calendar,ocsigen-toolkit.$(1) \
                -intro doc/indexdoc.$(1) $(COMMON_OPTIONS) \
                -i $(shell ocamlfind query wikidoc) \
                -g odoc_wiki.cma \
                -d doc/$(1)/wiki \
                -hide-warnings \
                $(2)

eliomdoc_html = ODOC_WIKI_SUBPROJECT="$(1)" \
                eliomdoc \
                -$(1) \
                -ppx -package pgocaml,yojson,calendar,ocsigen-toolkit.$(1) \
                -intro doc/indexdoc.$(1) \
                $(COMMON_OPTIONS) \
                -html \
                -d doc/$(1)/html \
                -hide-warnings \
                $(2)

doc:
	rm -rf doc/client
	rm -rf doc/server
	mkdir -p doc/client/html
	mkdir -p doc/client/wiki
	mkdir -p doc/server/html
	mkdir -p doc/server/wiki
	$(call eliomdoc_html,client, $(CLIENT_INC_DIRS) $(CLIENT_FILES_DOC))
	$(call eliomdoc_wiki,client, $(CLIENT_INC_DIRS) $(CLIENT_FILES_DOC))
	$(call eliomdoc_html,server, $(SERVER_INC_DIRS) $(SERVER_FILES_DOC))
	$(call eliomdoc_wiki,server, $(SERVER_INC_DIRS) $(SERVER_FILES_DOC))

##----------------------------------------------------------------------
## Clean up

clean:
	-rm -f *.cm[ioax] *.cmxa *.cmxs *.o *.a *.annot
	-rm -f *.type_mli
	-rm -f META
	-rm -rf ${ELIOM_CLIENT_DIR} ${ELIOM_SERVER_DIR} ${LIBDIR}
	-rm -f $(SASS_TEMPORARY_FILENAME).*
	-rm -rf .sass-cache

distclean: clean
	-rm -rf $(DEPSDIR) .depend
