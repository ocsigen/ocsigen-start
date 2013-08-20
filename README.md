#Eliom-Base-App

1. [Getting started](#getting-started)

##<a id="getting-started"></a>Getting started
1. [Create your database](#create-your-database)
2. [Set up EBA for eliom](#set-up-eba-for-eliom)
- - -

**Do not forget to add `eliom-base-app.client` and `eliom-base-app.server` package into your Makefile !**

###<a id="create-your-database"></a>Create your database

There is two importants things to do, before using EBA.

First, you have to create the database used by EBA (we're using `postgresql`).

NOTE: if you're using a local database, you have to give `-D <dir>` option to all of your `pg_ctl` commands.
```shell
# if you want to create a local database
mkdir <dir>
pg_ctl initdb -D <dir>
pg_ctl -D <dir> -l <logfile> start
createdb <db_name>
psql -d <db_name> -f eba_createdb.sql
```
- - -
**QUICK SET UP** (with all the default settings for EBA):
```shell
mkdir db_data
pg_ctl initdb -D db_data
pg_ctl -D db_data -l db_data/db_log start
createdb eba
psql -d eba -f eba_createdb.sql
```

Be sure that your database is now ready to use:
```shell
pg_ctl status -D <dir>
```
It should return something like:
```shell
pg_ctl: server is running (PID: XXXX)
/your/binary/path/for/postgresql/X.X.X/bin/postgres "-D" "<dir>"
```

- - -
###<a id="set-up-eba-for-eliom"></a>Set up EBA for eliom

You have to create a file and include **functor** instance into it.
```shell
vim ebapp.eliom
```
Add the followings code into your new ml file:
```ocaml
include Eba_main.App(struct
  include Eba_main.App_default
end)
```
- - -
**The following parts of the README are currently in work in progress.**
- - -
You can also add more config object into the module parameter of the functor:
```ocaml
include Eba_main.App(struct
  include Eba_main.App_default

  (* config the the application *)
  let app_config = object
    method name = "your-app-name"
    method css = [
        ["your-css"]
    ]
    method js = [
        ["your-js"]
    ]
  end
  
  (* config for the database *)
  let db_config = object
    method name = <db_name>
    method port = <db_port>
    method workers = <db_workers>
    method hash s = ...
    method verify s1 s2 = ...
  end

  (* config for the session *)
  let session_config = object
    method on_open_session = ...
    method on_close_session = ...
    method on_start_process = ...
    method on_start_connected_process = ...
  end
end)

```
