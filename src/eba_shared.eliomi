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

{server{
  module Page : sig
    type page =
      [ Html5_types.html ] Eliom_content.Html5.elt
    type page_content =
      [ Html5_types.body_content ] Eliom_content.Html5.elt list
  end
}}

{client{
  module Email : sig
    val email_pattern : string
    val is_valid : string -> bool
  end
}}

{server{
  module Email : sig
    val email_pattern : string
  end
}}
