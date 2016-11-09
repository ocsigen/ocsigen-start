#----------------------------------------------------------------------
#           OCSIGEN-START MAKEFILE, NOT TO BE MODIFIED
#----------------------------------------------------------------------

##----------------------------------------------------------------------
## DISCLAIMER
##
## This file contains the rules to make an Eliom project. The project is
## configured through the variables in the file Makefile.options.
##----------------------------------------------------------------------

##----------------------------------------------------------------------
##                Internals

## Required binaries
ELIOMC            := eliomc -w +A-4-7-9-37-38-39-41-42-44-45-48
ELIOMOPT          := eliomopt
JS_OF_ELIOM       := js_of_eliom -w +A-4-7-9-37-38-39-41-42-44-45-48
JS_OF_OCAML       := js_of_ocaml
ELIOMDEP          := eliomdep
OCSIGENSERVER     := ocsigenserver
OCSIGENSERVER.OPT := ocsigenserver.opt

## Where to put intermediate object files.
## - ELIOM_{SERVER,CLIENT}_DIR must be distinct
## - ELIOM_CLIENT_DIR must not be the local dir.
## - ELIOM_SERVER_DIR could be ".", but you need to
##   remove it from the "clean" rules...
export ELIOM_SERVER_DIR := _server
export ELIOM_CLIENT_DIR := _client
export ELIOM_TYPE_DIR   := _server
DEPSDIR := _deps

ifeq ($(DEBUG),yes)
  GENERATE_DEBUG ?= -g
  RUN_DEBUG ?= "-v"
  DEBUG_JS ?= --noinline --disable=shortvar --pretty
      #  --debuginfo
endif

##----------------------------------------------------------------------

##----------------------------------------------------------------------
## General

.PHONY: all css byte opt

DIST_DIRS          := $(ETCDIR) $(DATADIR) $(LIBDIR) $(LOGDIR) $(STATICDIR) \
                      $(FILESDIR)/avatars/tmp $(ELIOMSTATICDIR) \
                      $(shell dirname $(CMDPIPE)) $(ELIOMTMPDIR)
JS_PREFIX          := $(TEST_PREFIX)$(ELIOMSTATICDIR)/$(PROJECT_NAME)

CONF_IN            := $(wildcard *.conf.in)
CONFIG_FILES       := $(patsubst %.conf.in,$(TEST_PREFIX)$(ETCDIR)/%.conf,$(CONF_IN))
TEST_CONFIG_FILES  := $(patsubst %.conf.in,$(TEST_PREFIX)$(ETCDIR)/%-test.conf,$(CONF_IN))


all: css byte opt

byte:: $(TEST_PREFIX)$(LIBDIR)/${PROJECT_NAME}.cma
opt:: $(TEST_PREFIX)$(LIBDIR)/${PROJECT_NAME}.cmxs

byte opt:: ${JS_PREFIX}.js
byte opt:: $(CONFIG_FILES)

##----------------------------------------------------------------------

##----------------------------------------------------------------------
## The following part has been generated with os template.
## This will overload the default required binaries.

## DO NOT MOVE IT ON TOP OF THE `all` RULE!

include Makefile.$(PROJECT_NAME)

## end of `include Makefile.$(PROJECT_NAME)`
##----------------------------------------------------------------------

##----------------------------------------------------------------------
## Testing

DIST_FILES = $(ELIOMSTATICDIR)/$(PROJECT_NAME).js $(LIBDIR)/$(PROJECT_NAME).cma

.PHONY: test.byte test.opt staticfiles
test.byte: $(TEST_CONFIG_FILES) staticfiles $(addprefix $(TEST_PREFIX),$(DIST_DIRS) $(DIST_FILES)) css
	@echo "==== The website is available at http://localhost:$(TEST_PORT) ===="
	$(OCSIGENSERVER) $(RUN_DEBUG) -c $<
test.opt: $(TEST_CONFIG_FILES) $(addprefix $(TEST_PREFIX),$(DIST_DIRS) $(patsubst %.cma,%.cmxs, $(DIST_FILES))) css
	@echo "==== The website is available at http://localhost:$(TEST_PORT) ===="
	$(OCSIGENSERVER.OPT) $(RUN_DEBUG) -c $<

$(addprefix $(TEST_PREFIX), $(DIST_DIRS)):
	mkdir -p $@

staticfiles:
	cp -rf $(LOCAL_STATIC_CSS) $(LOCAL_STATIC_FONTS) $(TEST_PREFIX)$(ELIOMSTATICDIR)

##----------------------------------------------------------------------
## Installing & Running

.PHONY: install install.byte install.byte install.opt install.static install.etc install.lib install.lib.byte install.lib.opt run.byte run.opt
install: install.byte install.opt
install.byte: install.lib.byte install.etc install.static | $(addprefix $(PREFIX),$(DATADIR) $(LOGDIR) $(shell dirname $(CMDPIPE)))
install.opt: install.lib.opt install.etc install.static | $(addprefix $(PREFIX),$(DATADIR) $(LOGDIR) $(shell dirname $(CMDPIPE)))
install.lib: install.lib.byte install.lib.opt
install.lib.byte: $(TEST_PREFIX)$(LIBDIR)/$(PROJECT_NAME).cma | $(PREFIX)$(LIBDIR)
	install $< $(PREFIX)$(LIBDIR)
install.lib.opt: $(TEST_PREFIX)$(LIBDIR)/$(PROJECT_NAME).cmxs | $(PREFIX)$(LIBDIR)
	install $< $(PREFIX)$(LIBDIR)
install.static: $(TEST_PREFIX)$(ELIOMSTATICDIR)/$(PROJECT_NAME).js | $(PREFIX)$(STATICDIR) $(PREFIX)$(ELIOMSTATICDIR)
	cp -r $(LOCAL_STATIC_CSS) $(PREFIX)$(FILESDIR)
	cp -r $(LOCAL_STATIC_FONTS) $(PREFIX)$(FILESDIR)
	[ -z $(WWWUSER) ] || chown -R $(WWWUSER) $(PREFIX)$(FILESDIR)
	install $(addprefix -o ,$(WWWUSER)) $< $(PREFIX)$(ELIOMSTATICDIR)
install.etc: $(TEST_PREFIX)$(ETCDIR)/$(PROJECT_NAME).conf | $(PREFIX)$(ETCDIR)
	install $< $(PREFIX)$(ETCDIR)/$(PROJECT_NAME).conf

.PHONY:
print-install-files:
	@echo $(PREFIX)$(LIBDIR)
	@echo $(PREFIX)$(ELIOMSTATICDIR)
	@echo $(PREFIX)$(ETCDIR)

$(addprefix $(PREFIX),$(ETCDIR) $(LIBDIR)):
	install -d $@
$(addprefix $(PREFIX),$(DATADIR) $(LOGDIR) $(ELIOMSTATICDIR) $(shell dirname $(CMDPIPE))):
	install $(addprefix -o ,$(WWWUSER)) -d $@

run.byte:
	@echo "==== The website is available at http://localhost:$(PORT) ===="
	$(OCSIGENSERVER) $(RUN_DEBUG) -c ${PREFIX}${ETCDIR}/${PROJECT_NAME}.conf
run.opt:
	@echo "==== The website is available at http://localhost:$(PORT) ===="
	$(OCSIGENSERVER.OPT) $(RUN_DEBUG) -c ${PREFIX}${ETCDIR}/${PROJECT_NAME}.conf

##----------------------------------------------------------------------

##----------------------------------------------------------------------
## Aux

# Use `eliomdep -sort' only in OCaml>4
#ifeq ($(shell ocamlc -version|cut -c1),4)
#eliomdep=$(shell $(ELIOMDEP) $(1) -ppx -sort $(2) $(filter %.eliom %.ml,$(3))))
#else
#eliomdep=$(3)
#endif
objs=$(patsubst %.ml,$(1)/%.$(2),$(patsubst %.eliom,$(1)/%.$(2),$(filter %.eliom %.ml,$(3))))
#depsort=$(call objs,$(1),$(2),$(call eliomdep,$(3),$(4),$(5)))
depsort=$(shell ocaml tools/sort_deps.ml .depend $(patsubst %.ml,$(1)/%.$(2),$(patsubst %.eliom,$(1)/%.$(2),$(filter %.eliom %.ml,$(5)))))

##----------------------------------------------------------------------

##----------------------------------------------------------------------
## Config files

ELIOM_MODULES=$(patsubst %,\<eliommodule\ findlib-package=\"%\"\ /\>,$(SERVER_ELIOM_PACKAGES))
FINDLIB_PACKAGES=$(patsubst %,\<extension\ findlib-package=\"%\"\ /\>,$(SERVER_PACKAGES))
EDIT_WARNING=DON\'T EDIT THIS FILE! It is generated from $(PROJECT_NAME).conf.in, edit that one, or the variables in Makefile.options
SED_ARGS = -e "/^ *%%%/d"
SED_ARGS += -e "s|%%PROJECT_NAME%%|$(PROJECT_NAME)|g"
SED_ARGS += -e "s|%%DB_NAME%%|$(DB_NAME)|g"
SED_ARGS += -e "s|%%DB_HOST%%|$(DB_HOST)|g"
SED_ARGS += -e "s|%%DB_PORT%%|$(DB_PORT)|g"
SED_ARGS += -e "s|%%DB_USER%%|$(DB_USER)|g"
SED_ARGS += -e "s|%%DB_PASSWORD%%|$(DB_PASSWORD)|g"
SED_ARGS += -e "s|%%CMDPIPE%%|%%PREFIX%%$(CMDPIPE)|g"
SED_ARGS += -e "s|%%LOGDIR%%|%%PREFIX%%$(LOGDIR)|g"
SED_ARGS += -e "s|%%DATADIR%%|%%PREFIX%%$(DATADIR)|g"
SED_ARGS += -e "s|%%LIBDIR%%|%%PREFIX%%$(LIBDIR)|g"
SED_ARGS += -e "s|%%WARNING%%|$(EDIT_WARNING)|g"
SED_ARGS += -e "s|%%PACKAGES%%|$(FINDLIB_PACKAGES)|g"
SED_ARGS += -e "s|%%ELIOM_MODULES%%|$(ELIOM_MODULES)|g"
SED_ARGS += -e "s|%%FILESDIR%%|%%PREFIX%%$(FILESDIR)|g"
SED_ARGS += -e "s|%%ELIOMSTATICDIR%%|%%PREFIX%%$(ELIOMSTATICDIR)|g"
SED_ARGS += -e "s|%%APPNAME%%|$(shell basename `readlink $(JS_PREFIX).js` .js)|g"
SED_ARGS += -e "s|%%CSSNAME%%|$(shell readlink $(CSS_PREFIX).css)|g"
ifeq ($(DEBUG),yes)
  SED_ARGS += -e "s|%%DEBUGMODE%%|\<debugmode /\>|g"
else
  SED_ARGS += -e "s|%%DEBUGMODE%%||g"
endif

LOCAL_SED_ARGS := -e "s|%%PORT%%|$(TEST_PORT)|g"
LOCAL_SED_ARGS += -e "s|%%USERGROUP%%||g"
GLOBAL_SED_ARGS := -e "s|%%PORT%%|$(PORT)|g"
ifeq ($(WWWUSER)$(WWWGROUP),)
  GLOBAL_SED_ARGS += -e "s|%%USERGROUP%%||g"
else
  GLOBAL_SED_ARGS += -e "s|%%USERGROUP%%|<user>$(WWWUSER)</user><group>$(WWWGROUP)</group>|g"
endif

ifneq ($(DO_NOT_RECOMPILE),yes)
JS_AND_CSS=$(JS_PREFIX).js $(CSS_PREFIX).css
endif

$(CONFIG_FILES): $(TEST_PREFIX)$(ETCDIR)/%.conf: %.conf.in Makefile.options $(JS_AND_CSS) | $(TEST_PREFIX)$(ETCDIR)
	sed $(SED_ARGS) $(GLOBAL_SED_ARGS) $< | sed -e "s|%%PREFIX%%|$(PREFIX)|g" > $@

$(TEST_CONFIG_FILES): $(TEST_PREFIX)$(ETCDIR)/%-test.conf: %.conf.in Makefile.options $(JS_AND_CSS) | $(TEST_PREFIX)$(ETCDIR)
	sed $(SED_ARGS) $(LOCAL_SED_ARGS) $< | sed -e "s|%%PREFIX%%|$(TEST_PREFIX)|g" > $@

##----------------------------------------------------------------------

##----------------------------------------------------------------------
## Server side compilation

SERVER_INC_DEP  := ${addprefix -package ,${SERVER_PACKAGES} ${SERVER_ELIOM_PACKAGES}}
SERVER_INC  := ${addprefix -package ,${SERVER_PACKAGES} ${SERVER_ELIOM_PACKAGES}}
SERVER_DB_INC  := ${addprefix -package ,${SERVER_PACKAGES} ${SERVER_DB_PACKAGES} ${SERVER_ELIOM_PACKAGES}}

${ELIOM_TYPE_DIR}/%.type_mli: %.eliom
	${ELIOMC} -ppx -infer ${SERVER_INC} $<

$(TEST_PREFIX)$(LIBDIR)/$(PROJECT_NAME).cma: $(call objs,$(ELIOM_SERVER_DIR),cmo,$(SERVER_FILES)) | $(TEST_PREFIX)$(LIBDIR)
	${ELIOMC} -a -o $@ $(GENERATE_DEBUG) \
          $(call depsort,$(ELIOM_SERVER_DIR),cmo,-server,$(SERVER_DB_INC),$(SERVER_FILES))

$(TEST_PREFIX)$(LIBDIR)/$(PROJECT_NAME).cmxa: $(call objs,$(ELIOM_SERVER_DIR),cmx,$(SERVER_FILES)) | $(TEST_PREFIX)$(LIBDIR)
	${ELIOMOPT} -a -o $@ $(GENERATE_DEBUG) \
          $(call depsort,$(ELIOM_SERVER_DIR),cmx,-server,$(SERVER_DB_INC),$(SERVER_FILES))

%.cmxs: %.cmxa
	$(ELIOMOPT) -shared -linkall -o $@ $(GENERATE_DEBUG) $<

${ELIOM_SERVER_DIR}/%_db.cmi: %_db.mli
	${ELIOMC} -c ${SERVER_DB_INC} $(GENERATE_DEBUG) $<
${ELIOM_SERVER_DIR}/%.cmi: %.mli
	${ELIOMC} -c ${SERVER_INC} $(GENERATE_DEBUG) $<

${ELIOM_SERVER_DIR}/%.cmi: %.eliomi
	${ELIOMC} -ppx -c ${SERVER_INC} $(GENERATE_DEBUG) $<

${ELIOM_SERVER_DIR}/%_db.cmo: %_db.ml
	${ELIOMC} -c ${SERVER_DB_INC} $(GENERATE_DEBUG) $<
${ELIOM_SERVER_DIR}/%.cmo: %.ml
	${ELIOMC} -c ${SERVER_INC} $(GENERATE_DEBUG) $<
${ELIOM_SERVER_DIR}/%.cmo: %.eliom
	${ELIOMC} -ppx -c ${SERVER_INC} $(GENERATE_DEBUG) $<

${ELIOM_SERVER_DIR}/%_db.cmx: %_db.ml
	${ELIOMOPT} -c ${SERVER_DB_INC} $(GENERATE_DEBUG) $<
${ELIOM_SERVER_DIR}/%.cmx: %.ml
	${ELIOMOPT} -c ${SERVER_INC} $(GENERATE_DEBUG) $<
${ELIOM_SERVER_DIR}/%.cmx: %.eliom
	${ELIOMOPT} -ppx -c ${SERVER_INC} $(GENERATE_DEBUG) $<

##----------------------------------------------------------------------

##----------------------------------------------------------------------
## Client side compilation

CLIENT_LIBS := ${addprefix -package ,${CLIENT_PACKAGES}}
CLIENT_INC  := ${addprefix -package ,${CLIENT_PACKAGES}}

CLIENT_OBJS := $(filter %.eliom %.ml, $(CLIENT_FILES))
CLIENT_OBJS := $(patsubst %.eliom,${ELIOM_CLIENT_DIR}/%.cmo, ${CLIENT_OBJS})
CLIENT_OBJS := $(patsubst %.ml,${ELIOM_CLIENT_DIR}/%.cmo, ${CLIENT_OBJS})

$(ELIOM_CLIENT_DIR)/os_prologue.js:
	${JS_OF_ELIOM} -jsopt --dynlink -o $@ $(GENERATE_DEBUG) $(CLIENT_INC) \
		${addprefix -jsopt ,$(DEBUG_JS)}

ifeq ($(DEBUG),yes)
$(JS_PREFIX).js: $(call objs,$(ELIOM_CLIENT_DIR),js,$(CLIENT_FILES)) | $(TEST_PREFIX)$(ELIOMSTATICDIR) $(ELIOM_CLIENT_DIR)/os_prologue.js
	cat $(ELIOM_CLIENT_DIR)/os_prologue.js $(call depsort,$(ELIOM_CLIENT_DIR),js,-client,$(CLIENT_INC),$(CLIENT_FILES)) > $(JS_PREFIX)_tmp.js && \
	HASH=`md5sum $(JS_PREFIX)_tmp.js | cut -d ' ' -f 1` && \
	mv $(JS_PREFIX)_tmp.js $(JS_PREFIX)_$$HASH.js && \
	ln -sf $(PROJECT_NAME)_$$HASH.js $@
else
(JS_PREFIX).js: $(call objs,$(ELIOM_CLIENT_DIR),cmo,$(CLIENT_FILES)) | $(TEST_PREFIX)$(ELIOMSTATICDIR)
	${JS_OF_ELIOM} -ppx -o $(JS_PREFIX)_tmp.js $(GENERATE_DEBUG) $(CLIENT_INC) ${addprefix -jsopt ,$(DEBUG_JS)} \
          $(call depsort,$(ELIOM_CLIENT_DIR),cmo,-client,$(CLIENT_INC),$(CLIENT_FILES))
	HASH=`md5sum $(JS_PREFIX)_tmp.js | cut -d ' ' -f 1` && \
	mv $(JS_PREFIX)_tmp.js $(JS_PREFIX)_$$HASH.js && \
	ln -sf $(PROJECT_NAME)_$$HASH.js $@
endif

${ELIOM_CLIENT_DIR}/%.cmi: %.mli
	${JS_OF_ELIOM} -c ${CLIENT_INC} $(GENERATE_DEBUG) $<

${ELIOM_CLIENT_DIR}/%.cmo: %.eliom
	${JS_OF_ELIOM} -ppx -c ${CLIENT_INC} $(GENERATE_DEBUG) $<

${ELIOM_CLIENT_DIR}/%.cmo: %.ml
	${JS_OF_ELIOM} -c ${CLIENT_INC} $(GENERATE_DEBUG) $<

${ELIOM_CLIENT_DIR}/%.cmi: %.eliomi
	${JS_OF_ELIOM} -ppx -c ${CLIENT_INC} $(GENERATE_DEBUG) $<

${ELIOM_CLIENT_DIR}/%.js: ${ELIOM_CLIENT_DIR}/%.cmo
	${JS_OF_OCAML} $(DEBUG_JS) $<

##----------------------------------------------------------------------

##----------------------------------------------------------------------
## Dependencies

# DO NOT include `.depend' for the following commands: db-*, clean, distclean
is_db_command=$(shell echo $(1) | grep -q "db-" && echo "true" || echo "false")
ifneq ($(call is_db_command,$(MAKECMDGOALS)),true)
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(MAKECMDGOALS),distclean)
include .depend
endif
endif
endif

.depend: $(patsubst %,$(DEPSDIR)/%.server,$(SERVER_FILES)) $(patsubst %,$(DEPSDIR)/%.client,$(CLIENT_FILES))
	@cat $^ > $@

$(DEPSDIR)/%.ml.server: %.ml | $(DEPSDIR) $(SERVER_FILES)
	$(ELIOMDEP) -server $(SERVER_DB_INC) $< > $@.tmp && mv $@.tmp $@

$(DEPSDIR)/%.mli.server: %.mli | $(DEPSDIR) $(SERVER_FILES)
	$(ELIOMDEP) -server $(SERVER_DB_INC) $< > $@.tmp && mv $@.tmp $@

$(DEPSDIR)/%.eliom.server: %.eliom | $(DEPSDIR) $(SERVER_FILES)
	$(ELIOMDEP) -server -ppx $(SERVER_INC_DEP) $< > $@.tmp && mv $@.tmp $@

$(DEPSDIR)/%.eliomi.server: %.eliomi | $(DEPSDIR) $(SERVER_FILES)
	$(ELIOMDEP) -server -ppx $(SERVER_INC_DEP) $< > $@.tmp && mv $@.tmp $@

$(DEPSDIR)/%.ml.client: %.ml | $(DEPSDIR)
	$(ELIOMDEP) -client $(CLIENT_INC) $< > $@.tmp && mv $@.tmp $@

$(DEPSDIR)/%.eliom.client: %.eliom | $(DEPSDIR)
	$(ELIOMDEP) -client -ppx $(CLIENT_INC) $< > $@.tmp && mv $@.tmp $@

$(DEPSDIR)/%.eliomi.client: %.eliomi | $(DEPSDIR)
	$(ELIOMDEP) -client -ppx $(CLIENT_INC) $< > $@.tmp && mv $@.tmp $@

$(DEPSDIR):
	mkdir $@

##----------------------------------------------------------------------

##----------------------------------------------------------------------
## Clean up

clean:: clean-style mobile-clean
	-rm -f *.cm[ioax] *.cmxa *.cmxs *.o *.a *.annot
	-rm -f *.type_mli
	-rm -rf ${ELIOM_CLIENT_DIR} ${ELIOM_SERVER_DIR}

distclean: clean
	-rm -rf $(TEST_PREFIX) $(DEPSDIR) .depend
