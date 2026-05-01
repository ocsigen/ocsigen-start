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

Wiki API pages are generated from the `.eliomi` and `.mli` files using
`eliomdoc` and the [wikidoc](https://github.com/ocsigen/wikidoc) plugin:

```bash
bash build/gen_wikidoc.sh        # all (server + client)
bash build/gen_wikidoc.sh server # server side only
bash build/gen_wikidoc.sh client # client side only
```

Output goes to `_build/doc/dev/api/{server,client}/`.

The wiki files are published on the [wikidoc branch] under
`doc/dev/api/{server,client}/`. To update the published documentation,
copy the generated `.wiki` files to a checkout of the `wikidoc` branch
and commit.

[wikidoc branch]: https://github.com/ocsigen/ocsigen-start/tree/wikidoc/doc/dev/api
