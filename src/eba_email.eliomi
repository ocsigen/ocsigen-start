class type config = object
  method from_addr : (string * string)
  method mailer : string
end

module type T = sig
  exception Invalid_mailer of string

  val email_pattern : string
  val is_valid : string -> bool
  val send :    ?from_addr:(string * string)
             -> to_addrs:(string * string) list
             -> subject:string
             -> string list
             -> unit
end

module Make : functor (M :
sig
  val config : config

  module Rmsg : Eba_rmsg.T
end) -> T
