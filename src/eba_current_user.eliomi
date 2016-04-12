
[%%shared.start]

val get_current_user : unit -> Eba_user.t
val get_current_userid : unit -> int64

module Opt : sig
  val get_current_user : unit -> Eba_user.t option
  val get_current_userid : unit -> int64 option
end

[%%client.start]

type current_user =
  | CU_idontknown
  | CU_notconnected
  | CU_user of Eba_user.t

val me : current_user ref
