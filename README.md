# Ocsigen Start [![Build](https://github.com/ocsigen/ocsigen-start/actions/workflows/build.yml/badge.svg)](https://github.com/ocsigen/ocsigen-start/actions/workflows/build.yml)

You can try the [online version](https://ocsigen.org/ocsigen-start/demo) and
download
the
[Android application](https://play.google.com/store/apps/details?id=com.osdemo.mobile&hl=en).

1. [Introduction](#introduction)
2. [Installation](#install)
3. [Create your project](#create-your-project)

### <a id="introduction"></a>Introduction
Ocsigen Start is a set of higher-level libraries for building
client-server web applications with Ocsigen (Js_of_ocaml and
Eliom). It provides modules for
* user management (session management, registration, action — e.g., activation — keys, ...),
* managing groups of users,
* displaying tips, and
* easily sending notifications to the users.

Ocsigen Start comes with an `eliom-distillery` template for an app
with a database, user management, and session management.  This
template is intended to serve as a basis for quickly building the
Minimum Viable Product for web applications with users. The goal is to
enable the programmer to concentrate on the core of the app, and not
on user management.

If Ocsigen Start corresponds to your needs, it will probably help you
a lot. If not, start with a simpler template. You can still use the
modules from Ocsigen Start.

### <a id="install"></a>Installation

We recommend using OPAM to install Ocsigen Start. Here is the command:

```
opam install ocsigen-start
```

### <a id="create-your-project"></a>Create your project
```
eliom-distillery -name myproject -template os.pgocaml
```

To get started, take a look at the generated README.md.

You have also the complete manual and API available on
the [Ocsigen website](http://ocsigen.org/ocsigen-start/)

### Generating API documentation

The API documentation is generated using `eliomdoc` (installed with Eliom)
and the `wikidoc` ocamldoc plugin. Generated wiki files are stored in the
`wikidoc` branch under `doc/dev/api/`.

```bash
# Generate server documentation
eliomdoc -server -ppx -colorize-code -stars -sort \
  -package eliom.server,calendar,ocsigenserver,ocsipersist,pgocaml,pgocaml_ppx,macaddr,yojson,ocsigen-toolkit.server,resource-pooling \
  -I _build/default/src/.ocsigen_start.objs/byte \
  -i $(ocamlfind query wikidoc) -g odoc_wiki.cma \
  -d _build/doc/server -subproject server \
  src/*.eliomi src/*.mli

# Generate client documentation
eliomdoc -client -ppx -colorize-code -stars -sort \
  -package eliom.client,calendar,ocsigen-toolkit.client,js_of_ocaml,js_of_ocaml-lwt \
  -I _build/default/src/.ocsigen_start.objs/byte \
  -i $(ocamlfind query wikidoc) -g odoc_wiki.cma \
  -d _build/doc/client -subproject client \
  src/*.eliomi

# Then copy to the wikidoc branch:
git checkout wikidoc
cp _build/doc/server/*.wiki doc/dev/api/server/
cp _build/doc/client/*.wiki doc/dev/api/client/
```
