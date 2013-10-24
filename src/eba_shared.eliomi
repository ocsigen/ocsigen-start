{shared{
  module User : sig
    type t = Eba_types.User.t deriving (Json)

    val default_avatar : string
    val make_avatar_uri : string -> Eliom_content.Html5.uri
    val make_avatar_string_uri : ?absolute:bool -> string -> string

    val is_new : t -> bool
    val firstname_of_user : t -> string
    val lastname_of_user : t -> string
    val fullname_of_user : t -> string
    val uid_of_user : t -> int64
    val avatar_of_user : t -> string
  end

  module Groups : sig
    type t = Eba_types.Groups.t

    val id_of_group : t -> int64
    val name_of_group : t -> string
    val desc_of_group : t -> string option
  end

  module Egroups : sig
    type t = Eba_types.Egroups.t

    val id_of_egroup : t -> int64
    val name_of_egroup : t -> string
    val desc_of_egroup : t -> string option
  end
}}

{server{
  module Session : sig
    exception Not_connected
  end
}}

{client{
  module Session : sig
    exception Not_connected

    val me : Eba_types.User.t option ref
    val get_current_user_option : unit -> Eba_types.User.t option
    val get_current_user_or_fail : unit -> Eba_types.User.t
  end
}}
