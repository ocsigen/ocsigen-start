###### OL (ocsigen package)

## Do not forget to install OL package before compiling this project !

You can find OL packages sources in the installation directory.

To install the package, you just need to run:
```shell
cd installation
make install
```

If you made some modifications on OL sources, you can run:
```shell
cd installation
make reinstall
```

This will reinstall the package.

If you add some files on OL package, you MUST distclean the directory and reinstall it:
```shell
cd installation
make distclean
make reinstall
```

## TODO
1. reorganize files (split more ? admin module, preregister module, register module, etc.. ?)
2. fix slowness of makefile dependencies for the OL package
3. add some helpers in preregistrations mode
4. add some files (ocaml script !) to manage the website easily:
    * swap mode: close/open
    * grant admin privilegies to a normal user using code instead of graphic admin interface)
    * above suggestions implies that we can use a console with the website environment (references, functions, etc..) (RAILS style)
