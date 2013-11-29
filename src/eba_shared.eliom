{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
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

{server{
  module Page = struct
    type page =
      [ Html5_types.html ] Eliom_content.Html5.elt
    type page_content =
      [ Html5_types.body_content ] Eliom_content.Html5.elt list
  end
}}

{shared{
  module Email' = struct
    let email_pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+[.][A-Z]+$"
  end
}}

{client{
  module Email = struct
    include Email'

    let regexp_email =
      Regexp.regexp_with_flag email_pattern "i"

    let is_valid email =
      match Regexp.string_match regexp_email email 0 with
        | None -> false
        | Some _ -> true
  end
}}

{server{
  module Email = struct
    include Email'
  end
}}
