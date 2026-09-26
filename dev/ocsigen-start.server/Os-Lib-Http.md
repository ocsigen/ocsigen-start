# Module `Lib.Http`

This module contains functions about HTTP request.

```ocaml
val string_of_stream : 
  ?len:int ->
  string Ocsigen_base.Ocsigen_stream.t ->
  string Lwt.t
```
`string_of_stream ?len stream` creates a string of maximum length `len` (default is `16384`) from the stream `stream`.
