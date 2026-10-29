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
OCSIGENSERVER     := ocsigenserver
OCSIGENSERVER.OPT := ocsigenserver.opt

ifneq ($(DEBUG),yes)
  DUNE_OPTIONS = --profile release
endif

##----------------------------------------------------------------------

##----------------------------------------------------------------------
## General

.PHONY: all css byte opt

DIST_DIRS          := $(ETCDIR) $(DATADIR) $(LOGDIR) \
                      $(FILESDIR)/avatars/tmp $(ELIOMSTATICDIR) \
                      $(shell dirname $(CMDPIPE))
JS_PREFIX          := $(TEST_PREFIX)$(ELIOMSTATICDIR)/$(PROJECT_NAME)

# Client code compiled by Dune. It is not part of @install, so the targets
# are built explicitly.
CLIENT_TARGETS     := app/client/main.bc.js
ifeq ($(USE_WASM),yes)
  CLIENT_TARGETS   += app/client/main.bc.wasm.js
endif
CLIENT_JS          := _build/default/app/client/main.bc.js
CLIENT_WASM        := _build/default/app/client/main.bc.wasm.js
CLIENT_WASM_ASSETS := _build/default/app/client/main.bc.wasm.assets

CONF_IN            := $(wildcard *.conf.in)
CONFIG_FILES       := $(patsubst %.conf.in,$(TEST_PREFIX)$(ETCDIR)/%.conf,$(CONF_IN))
TEST_CONFIG_FILES  := $(patsubst %.conf.in,$(TEST_PREFIX)$(ETCDIR)/%-test.conf,$(CONF_IN))


all:: css
all byte opt:: ${VOLATILE_SCHEMA}

##----------------------------------------------------------------------

##----------------------------------------------------------------------
## Testing

.PHONY: test.byte test.opt staticfiles byte opt

test.byte:: byte | $(addprefix $(TEST_PREFIX),$(DIST_DIRS)) staticfiles
	@echo "==== The website is available at http://localhost:$(TEST_PORT) ===="
	dune exec -- $(OCSIGENSERVER) $(RUN_DEBUG) -c $(patsubst %.conf.in,$(TEST_PREFIX)$(ETCDIR)/%-test.conf,$(CONF_IN))
test.opt:: opt | $(addprefix $(TEST_PREFIX),$(DIST_DIRS)) staticfiles
	@echo "==== The website is available at http://localhost:$(TEST_PORT) ===="
	dune exec -- $(OCSIGENSERVER.OPT) $(RUN_DEBUG) -c $(patsubst %.conf.in,$(TEST_PREFIX)$(ETCDIR)/%-test.conf,$(CONF_IN))

test.static.byte: static.byte | $(addprefix $(TEST_PREFIX),$(DIST_DIRS)) staticfiles
	@echo "==== The website is available at http://localhost:$(TEST_PORT) ===="
	dune exec app/main/main.bc
test.static.opt: static.opt | $(addprefix $(TEST_PREFIX),$(DIST_DIRS)) staticfiles
	@echo "==== The website is available at http://localhost:$(TEST_PORT) ===="
	dune exec app/main/main.exe

$(addprefix $(TEST_PREFIX), $(DIST_DIRS)):
	mkdir -p $@

staticfiles:
	cp -rf $(LOCAL_STATIC_CSS) $(LOCAL_STATIC_IMAGES) $(LOCAL_STATIC_FONTS) $(TEST_PREFIX)$(ELIOMSTATICDIR)

##----------------------------------------------------------------------
## Static executable

static.byte: byte
	dune build $(DUNE_OPTIONS) app/main/main.bc

static.opt: opt
	dune build $(DUNE_OPTIONS) app/main/main.exe

##----------------------------------------------------------------------
## Installing & Running

.PHONY: install install.exe install.byte install.opt install.static install.etc install.lib run.byte run.opt
install: install.lib install.etc install.static | $(addprefix $(PREFIX),$(DATADIR) $(LOGDIR) $(shell dirname $(CMDPIPE)))
install.byte install.opt install.exe: install
# The application is installed as the findlib package $(PROJECT_NAME) under
# $(PREFIX)lib, with the standalone executable under $(PREFIX)bin.
install.lib: byte
	dune install --prefix $(PREFIX)
install.static: $(TEST_PREFIX)$(ELIOMSTATICDIR)/$(PROJECT_NAME).js | $(PREFIX)$(STATICDIR) $(PREFIX)$(ELIOMSTATICDIR)
	cp -r $(LOCAL_STATIC_IMAGES) $(PREFIX)$(FILESDIR)
	cp -r $(LOCAL_STATIC_FONTS) $(PREFIX)$(FILESDIR)
	[ -z $(WWWUSER) ] || chown -R $(WWWUSER) $(PREFIX)$(FILESDIR)
	HASH=`md5sum $(CLIENT_JS) | cut -d ' ' -f 1` && \
	install $(addprefix -o ,$(WWWUSER)) $(JS_PREFIX)_$$HASH.js $(PREFIX)$(ELIOMSTATICDIR) && \
	ln -sf $(PROJECT_NAME)_$$HASH.js $(PREFIX)$(ELIOMSTATICDIR)/$(PROJECT_NAME).js && \
	if [ "$(USE_WASM)" = "yes" ]; then \
	  HASH_WASM=`md5sum $(CLIENT_WASM) | cut -d ' ' -f 1` && \
	  install $(addprefix -o ,$(WWWUSER)) $(JS_PREFIX)_$$HASH_WASM.wasm.js $(PREFIX)$(ELIOMSTATICDIR) && \
	  ln -sf $(PROJECT_NAME)_$$HASH_WASM.wasm.js $(PREFIX)$(ELIOMSTATICDIR)/$(PROJECT_NAME).wasm.js && \
	  if [ -d $(CLIENT_WASM_ASSETS) ]; then \
	    cp -rf $(CLIENT_WASM_ASSETS) $(PREFIX)$(ELIOMSTATICDIR)/; \
	  fi; \
	fi
	HASH=`cat $(LOCAL_CSS) | md5sum | cut -d ' ' -f 1` && \
	install $(addprefix -o ,$(WWWUSER)) $(CSS_PREFIX)_$$HASH.css $(PREFIX)$(ELIOMSTATICDIR)/css && \
	ln -sf $(PROJECT_NAME)_$$HASH.css $(PREFIX)$(ELIOMSTATICDIR)/css/$(PROJECT_NAME).css
install.etc: $(TEST_PREFIX)$(ETCDIR)/$(PROJECT_NAME).conf | $(PREFIX)$(ETCDIR)
	install $< $(PREFIX)$(ETCDIR)/$(PROJECT_NAME).conf

.PHONY:
print-install-files:
	@echo $(PREFIX)$(ELIOMSTATICDIR)
	@echo $(PREFIX)$(ETCDIR)

$(PREFIX)$(ETCDIR):
	install -d $@
$(addprefix $(PREFIX),$(DATADIR) $(LOGDIR) $(ELIOMSTATICDIR) $(shell dirname $(CMDPIPE))):
	install $(addprefix -o ,$(WWWUSER)) -d $@

run.byte:
	@echo "==== Running ocsigenserver with configuration file  ===="
	@echo "==== The website is available at http://localhost:$(PORT) ===="
	$(OCSIGENSERVER) $(RUN_DEBUG) -c ${PREFIX}${ETCDIR}/${PROJECT_NAME}.conf
run.opt:
	@echo "==== Running ocsigenserver with configuration file  ===="
	@echo "==== The website is available at http://localhost:$(PORT) ===="
	$(OCSIGENSERVER.OPT) $(RUN_DEBUG) -c ${PREFIX}${ETCDIR}/${PROJECT_NAME}.conf

run.static:
	@echo "==== Running static executable ===="
	@echo "==== The website is available at http://localhost:$(PORT) ===="
	${PROJECT_NAME}

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
SED_ARGS += -e "s|%%WARNING%%|$(EDIT_WARNING)|g"
SED_ARGS += -e "s|%%PACKAGES%%|$(FINDLIB_PACKAGES)|g"
SED_ARGS += -e "s|%%ELIOM_MODULES%%|$(ELIOM_MODULES)|g"
SED_ARGS += -e "s|%%FILESDIR%%|%%PREFIX%%$(FILESDIR)|g"
SED_ARGS += -e "s|%%ELIOMSTATICDIR%%|%%PREFIX%%$(ELIOMSTATICDIR)|g"
SED_ARGS += -e "s|%%APPNAME%%|$(shell basename `readlink $(JS_PREFIX).js` .js)|g"
SED_ARGS += -e "s|%%CSSNAME%%|$(shell readlink $(CSS_PREFIX).css)|g"
ifeq ($(USE_WASM),yes)
  SED_ARGS += -e "s|%%WASMATTR%%|wasm=\"$(shell basename `readlink $(JS_PREFIX).wasm.js` .wasm.js).wasm.js\"|g"
else
  SED_ARGS += -e "s|%%WASMATTR%%||g"
endif
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

JS_AND_CSS=$(JS_PREFIX).js $(CSS_PREFIX).css

$(CONFIG_FILES): $(TEST_PREFIX)$(ETCDIR)/%.conf: %.conf.in $(JS_AND_CSS) | $(TEST_PREFIX)$(ETCDIR)
	sed $(SED_ARGS) $(GLOBAL_SED_ARGS) $< | sed -e "s|%%PREFIX%%|$(PREFIX)|g" > $@

$(TEST_CONFIG_FILES): $(TEST_PREFIX)$(ETCDIR)/%-test.conf: %.conf.in $(JS_AND_CSS) | $(TEST_PREFIX)$(ETCDIR)
	sed $(SED_ARGS) $(LOCAL_SED_ARGS) $< | sed -e "s|%%PREFIX%%|$(TEST_PREFIX)|g" > $@

##----------------------------------------------------------------------

##----------------------------------------------------------------------
## Compilation

.PHONY: config-files

config-files: | $(TEST_PREFIX)$(ELIOMSTATICDIR)
	HASH=`md5sum $(CLIENT_JS) | cut -d ' ' -f 1` && \
	cp -f $(CLIENT_JS) $(JS_PREFIX)_$$HASH.js && \
	ln -sf $(PROJECT_NAME)_$$HASH.js $(JS_PREFIX).js && \
	if [ "$(USE_WASM)" = "yes" ]; then \
	  HASH_WASM=`md5sum $(CLIENT_WASM) | cut -d ' ' -f 1` && \
	  cp -f $(CLIENT_WASM) $(JS_PREFIX)_$$HASH_WASM.wasm.js && \
	  ln -sf $(PROJECT_NAME)_$$HASH_WASM.wasm.js $(JS_PREFIX).wasm.js && \
	  if [ -d $(CLIENT_WASM_ASSETS) ]; then \
	    cp -rf $(CLIENT_WASM_ASSETS) $(TEST_PREFIX)$(ELIOMSTATICDIR)/; \
	  fi; \
	fi
	$(MAKE) $(CONFIG_FILES) $(TEST_CONFIG_FILES) PROJECT_NAME=$(PROJECT_NAME)

all::
	$(ENV_PSQL) dune build $(DUNE_OPTIONS) @install $(CLIENT_TARGETS)

# Dune builds the bytecode and native versions together.
byte opt::
	$(ENV_PSQL) dune build $(DUNE_OPTIONS) @install $(CLIENT_TARGETS)
	$(MAKE) config-files PROJECT_NAME=$(PROJECT_NAME)

##----------------------------------------------------------------------

##----------------------------------------------------------------------
## Clean up

.PHONY: clean

clean::
	dune clean
