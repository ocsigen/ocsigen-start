(** This module defines an interface to create icons HTML element with
 * predefined style/value. It is supposed "Font Awesome" icons are used by
 * default (fa CSS class is added when using [icon classes]).
 * See http://fontawesome.io/ for more information and for the complete list of
 * CSS classes values.
 *)

[%%shared.start]

module Make(A : module type of Eliom_content.Html.F) = struct

  (** [icon classes] create an icon HTML attribute with "fa" and [classes]
   * as CSS classes.
   * The optional parameter is at the end to be able to add other CSS classes
   * with predefined icons.
   *)
  let icon classes
      ?(a = ([] : Html_types.i_attrib Eliom_content.Html.attrib list)) () =
    A.i ~a:(A.a_class ("fa" :: classes) :: a) []

  (* Add your own icons here. See http://fontawesome.io/icons/ for the complete
   * list of CSS classes available by default.
   *)

  (* Example for the user icon:
   *  let user = icon ["fa-user"; "fa-fw"]
   *)

end

module F = struct
  include Make(Eliom_content.Html.F)
end

module D = struct
  include Make(Eliom_content.Html.D)
end
