# Module `Os_platform`

```ocaml
type t = 
  | Android
  | IPhone
  | IPad
  | IPod
  | IWatch
  | BlackBerry
  | Windows
  | Unknown
```
Platform type.

```ocaml
val t_of_string : string -> t
```
```ocaml
val string_of_t : t -> string
```
```ocaml
val get : unit -> t
```
Return the platform as a type [`t`](./#type-t). The detection is based on the user agent.

```ocaml
val css_class : t -> string
```
Return `"os-platform"` where `platform` is the device platform.

CSS class for `IPhone`, `IPad`, `IWatch` and `IPod` is `"os-ios"`.

If the platform is `Unknown`, it returns `"os-unknown-platform"`.
