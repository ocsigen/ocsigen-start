{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

{shared{
  module User = struct
    type t = {
      uid: int64;
      firstname : string;
      lastname : string;
      avatar : string option;
    } deriving (Json)
  end

  module Groups = struct
    type t = {
      id : int64;
      name : string;
      desc : string option
    } deriving (Json)
  end
}}
