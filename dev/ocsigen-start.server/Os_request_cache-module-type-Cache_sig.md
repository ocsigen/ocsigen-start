# Module type `Os_request_cache.Cache_sig`

```ocaml
type key
```
The type of the key

```ocaml
type value
```
The type of the value

```ocaml
val has : key -> bool
```
Returns `true` if the key has been stored into the cache.

```ocaml
val set : key -> value -> unit
```
Set the corresponding `value` for a key.

```ocaml
val reset : key -> unit
```
Remove a `value` for the given key.

```ocaml
val get : key -> value Lwt.t
```
Get the value corresponding to the given key.
