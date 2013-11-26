{shared{
  module type TUser = sig
    val uid_of_user : 'a Eba_types.User.ext_t -> int64
    val ext_of_user : 'a Eba_types.User.ext_t -> 'a
  end

  module type TGroups = sig
    type t = Eba_types.Groups.t

    val id_of_group : t -> int64
    val name_of_group : t -> string
    val desc_of_group : t -> string option
  end

  module User : TUser
  module Groups : TGroups
}}

{server{
  module Session : sig
    exception Not_connected
  end
}}

{client{
  module Session : sig
    exception Not_connected

    val set_current_userid : int64 -> unit
    val get_current_userid : unit -> int64
    val unset_current_userid : unit -> unit
    module Opt : sig
      val get_current_userid : unit -> int64 option
    end
  end
}}

{client{
  module Email : sig
    val is_valid : string -> bool
  end
}}
