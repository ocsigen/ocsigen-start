# Parameter `Make.M`

```ocaml
type key
```
The type of your key.

```ocaml
type value
```
The type of the stored value.

```ocaml
val compare : key -> key -> int
```
The function used to compare keys.

```ocaml
val get : key -> value Lwt.t
```
This function is called when the value corresponding to a key is not yet stored into the cache.
