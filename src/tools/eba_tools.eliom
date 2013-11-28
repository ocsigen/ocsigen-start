module type T = sig
  module Rmsg_f : Rmsg_f.T
  module Cache_f : Cache_f.T
end

module Rmsg_f = Rmsg_f
module Cache_f = Cache_f
