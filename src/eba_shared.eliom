{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

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

  module User = struct
    open Eba_types.User

    let uid_of_user (u : 'a ext_t) =
      u.uid

    let ext_of_user (u : 'a ext_t) =
      u.ext
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
}}

{server{
  module Session = struct
    exception Not_connected
  end
}}

{client{
  module Session = struct
    exception Not_connected

    let userid : int64 option ref = ref None

    let set_current_userid uid =
      userid := Some uid

    let unset_current_userid () =
      userid := None

    let get_current_userid () =
      match !userid with
        | Some userid -> userid
        | None -> raise Not_connected

    module Opt = struct
      let get_current_userid () =
        !userid
    end
  end
}}

{client{
  module Email = struct
    let regexp_email =
      Regexp.regexp_with_flag Eba_config.Email.email_pattern "i"

    let is_valid email =
      match Regexp.string_match regexp_email email 0 with
        | None -> false
        | Some _ -> true
  end
}}
