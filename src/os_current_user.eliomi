
[%%shared.start]

val get_current_user : unit -> Os_user.t
val get_current_userid : unit -> Os_user.id

module Opt : sig
  val get_current_user : unit -> Os_user.t option
  val get_current_userid : unit -> Os_user.id option
end

[%%client.start]

type current_user =
  | CU_idontknown
  | CU_notconnected
  | CU_user of Os_user.t

val me : current_user ref
