class type config = object
  method from_addr : string -> (string * string)
  method to_addr : string -> (string * string)
end

module type T = sig
  val send :    ?from_addr:(string * string)
             -> to_addrs:(string list) -> subject:string
             -> (string -> string list Lwt.t)
             -> bool Lwt.t
end

module Make : functor (M :
sig
  val app_name : string
  val config : config

  module Rmsg : Eba_rmsg.T
end) -> T
