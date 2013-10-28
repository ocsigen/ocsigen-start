{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

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

  module User = struct
    open Eba_types.User

    let uid_of_user (u : 'a ext_t) =
      u.uid
  end

  module Groups = struct
    type t = Eba_types.Groups.t

    open Eba_types.Groups

    let id_of_group group =
      group.id

    let name_of_group group =
      group.name

    let desc_of_group group =
      group.desc
  end

  module Egroups = struct
    type t = Eba_types.Egroups.t

    open Eba_types.Egroups

    let id_of_egroup egroup =
      egroup.id

    let name_of_egroup egroup =
      egroup.name

    let desc_of_egroup egroup =
      egroup.desc
  end
}}

{server{
  module Session = struct
    exception Not_connected
  end
}}

{client{
  module Session = struct
    exception Not_connected

    let me : Eba_types.User.basic_t option ref = ref None

    let get_current_user_option () = !me

    let get_current_user_or_fail () =
      match !me with
        | Some a -> a
        | None ->
          Ojw_log.log "Not connected error in Eba_sessions";
          raise Not_connected
  end
}}
