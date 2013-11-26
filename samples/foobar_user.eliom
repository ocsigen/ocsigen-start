open Eba_types.User
open Foobar_types.User

include Ebapp.User

let firstname_of_user (u : Foobar_types.User.ext_t Eba_types.User.ext_t) =
  u.ext.fn

let lastname_of_user u =
  u.ext.ln

let username_of_user u =
  u.ext.fn^" "^u.ext.ln
