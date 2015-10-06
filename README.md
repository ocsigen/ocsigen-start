#Eliom-Base-App

1. [Getting started](#getting-started)

##<a id="getting-started"></a>Getting started
1. [Introduction](#introduction)
2. [Installation](#install)
3. [Create your project](#create-your-project)
4. [Create your database](#create-your-database)

###<a id="introduction"></a>Introduction
Eliom base app is a set of higer level libraries for building client-server Web application with Ocsigen (Js_of_ocaml and Eliom). It contains modules for
* user management (session management, registration, activation keys, ...),
* managing groups of users,
* displaying tips
* Sending notifications to users very easily

Eliom-base-app is in early stage of developement. More modules will be added and more customizability.

Eliom-base-app comes with an Eliom-distillery template which creates a full app with a database, and user and session management.
This template is intended to serve as a basis for quickly building Minimum Viable Product of Web applications with users. The goal is to make it possible for the programmer to concentrate on the core of the app, and not user management.

If it corresponds to your need, it will probably help you a lot.
If not, start with a simpler template (but you can still use the modules from Eliom-base-app).

###<a id="install"></a>Installation

Eliom-base-app depends on dev version of Eliom (branch shared react),
and dev version of tyxml, js_of_ocaml, ojquery, macaque, ocsigen-widgets and reactiveData.
Use opam to install it, after pinning the github repositories.

###<a id="create-your-project"></a>Create your project
```
eliom-distillery -name myproject -template eba.pgocaml
```

###<a id="create-your-database"></a>Create your database
Have look at file README in your directory.
It explains how to configure your database.

###<a id="configure-your-project"></a>Configure your project
