
{shared{

module Make(A : module type of Eliom_content.Html5.F) = struct

  let icon classes ?(class_=[]) () =
    A.i ~a:[A.a_class ("fa"::classes@class_)] []

  (* Add your own icons here *)

  (* Example:
     let user = icon ["fa-user"; "fa-fw"]
  *)

end

module F = struct
  include Ow_icons.F
  include Make(Eliom_content.Html5.F)
end

module D = struct
  include Ow_icons.D
  include Make(Eliom_content.Html5.D)
end



}}
