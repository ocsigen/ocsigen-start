
# Module `Os_request_cache.Make`

Functor which creates a module [`Cache_sig`](./Os_request_cache-module-type-Cache_sig.md).


## Parameters

```ocaml
module M : sig ... end
```

## Signature

```ocaml
type key = M.key
```
The type of the key

```ocaml
type value = M.value
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
