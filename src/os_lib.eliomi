[%%client.start]

val reload : unit -> unit Lwt.t

[%%shared.start]

val memoizator :
  (unit -> 'a Lwt.t)  ->
  unit                ->
  'a Lwt.t
