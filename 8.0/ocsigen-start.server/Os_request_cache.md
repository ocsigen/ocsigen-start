
# Module `Os_request_cache`

Caching request data to avoid doing the same computation several times during the same request.

```ocaml
module type Cache_sig = sig ... end
```
```ocaml
module Make
  (M : sig ... end) : 
  Cache_sig with type key = M.key and type value = M.value
```
Functor which creates a module [`Cache_sig`](./Os_request_cache-module-type-Cache_sig.md).
