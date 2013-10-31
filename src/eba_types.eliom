{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

{shared{
  module User = struct
    type 'a ext_t = {
      uid: int64;
      ext: 'a;
    } deriving (Json)

    type basic_t = unit ext_t deriving (Json)
  end

  module Groups = struct
    type t = {
      id : int64;
      name : string;
      desc : string option
    } deriving (Json)
  end

  type state_t = [ `Normal | `Restricted ] deriving (Json)

  type error_t = [
    | `Wrong_password
    | `Wrong_personal_data of ((string * string) * (string * string))
    | `Set_password_failed of string
    | `Send_mail_failed of string
    | `Activation_key_outdated
    | `User_already_preregistered of string
    | `User_does_not_exist of string
    | `User_already_exists of string
  ] deriving (Json)

  type notice_t = [
    | `Preregistered
    | `Activation_key_created
  ] deriving (Json)
}}
