# Ocsigen Start [![Travis Status][travis-img]][travis]

[travis]:      https://travis-ci.org/ocsigen/ocsigen-start/branches
[travis-img]:  https://img.shields.io/travis/ocsigen/ocsigen-start/master.svg?label=travis

1. [Getting started](#getting-started)

##<a id="getting-started"></a>Getting started
1. [Introduction](#introduction)
2. [Installation](#install)
3. [Create your project](#create-your-project)
4. [Create your database](#create-your-database)

###<a id="introduction"></a>Introduction
Ocsigen Start is a set of higher-level libraries for building
client-server web applications with Ocsigen (Js_of_ocaml and
Eliom). It provides modules for
* user management (session management, registration, activation keys, ...),
* managing groups of users,
* displaying tips, and
* easily sending notifications to the users.

Ocsigen Start is in an early stage of development. More modules will
be added and more customizability.

Ocsigen Start comes with an `eliom-distillery` template for an app
with a database, user management, and session management.  This
template is intended to serve as a basis for quickly building the
Minimum Viable Product for web applications with users. The goal is to
enable the programmer to concentrate on the core of the app, and not
on user management.

If Ocsigen Start corresponds to your needs, it will probably help you
a lot. If not, start with a simpler template. You can still use the
modules from Ocsigen Start.

###<a id="install"></a>Installation

We recommend using OPAM to install Ocsigen Start. Here is the command:

```
opam install ocsigen-start
```

###<a id="create-your-project"></a>Create your project
```
eliom-distillery -name myproject -template os.pgocaml
```

###<a id="create-your-database"></a>Create your database
Have look at the file README in your directory.
It explains how to configure your database.

###<a id="configure-your-project"></a>Configure your project
