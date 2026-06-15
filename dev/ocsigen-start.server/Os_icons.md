
# Module `Os_icons`

The icons used internally by Ocsigen Start's library. Customize them with your own icons by calling module `Register`.

```ocaml
module type ICSIG = sig ... end
```
```ocaml
module D : ICSIG
```
```ocaml
module F : ICSIG
```
```ocaml
module Register (_ : ICSIG) (_ : ICSIG) : sig ... end
```