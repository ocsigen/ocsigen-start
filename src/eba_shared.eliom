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
