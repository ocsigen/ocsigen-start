{shared{
  module type TUser = sig
    val uid_of_user : 'a Eba_types.User.ext_t -> int64
  end

  module type TGroups = sig
    type t = Eba_types.Groups.t

    val id_of_group : t -> int64
    val name_of_group : t -> string
    val desc_of_group : t -> string option
  end

  module type TEgroups = sig
    type t = Eba_types.Egroups.t

    val id_of_egroup : t -> int64
    val name_of_egroup : t -> string
    val desc_of_egroup : t -> string option
  end

  module User : TUser
  module Groups : TGroups
  module Egroups : TEgroups
}}

{server{
  module Session : sig
    exception Not_connected
  end
}}

{client{
  module Session : sig
    exception Not_connected

    val me : Eba_types.User.basic_t option ref
    val get_current_user_option : unit -> Eba_types.User.basic_t option
    val get_current_user_or_fail : unit -> Eba_types.User.basic_t
  end
}}
