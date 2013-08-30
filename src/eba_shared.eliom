{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

{shared{
  module User = struct
    type t = Eba_types.User.t deriving (Json)

    let default_avatar =
      "__eba_default_user_avatar"

    let make_avatar_uri p =
      make_uri (Eliom_service.static_dir ()) ["avatars" ; p]

    let make_avatar_string_uri ?absolute p =
      make_string_uri
        ?absolute ~service:(Eliom_service.static_dir ()) ["avatars" ; p]

    open Eba_types.User

    let is_new u =
      u.firstname = ""

    let firstname_of_user u =
      u.firstname

    let lastname_of_user u =
      u.lastname

    let fullname_of_user u =
      (u.firstname)^" "^(u.lastname)

    let uid_of_user u =
      u.uid

    let avatar_of_user u =
      match u.avatar with
        | None -> default_avatar
        | Some s -> s

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

    let me : Eba_types.User.t option ref = ref None

    let get_current_user_option () = !me

    let get_current_user_or_fail () =
      match !me with
        | Some a -> a
        | None ->
          Ojw_log.log "Not connected error in Eba_sessions";
          raise Not_connected
  end
}}
