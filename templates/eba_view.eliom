{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

module Make(M : sig module User : Eba_user.T end) = struct
  module Image = Eba_image.Make(struct module User = M.User end)
  module I = Image
end
