open Eliom_content.Html5.F
open Printf

let wrong_password =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let user_already_exists =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let user_does_not_exist =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let user_already_preregistered =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let activation_key_outdated =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let activation_key_created =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let wrong_pdata =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope
    (None : ((string * string) * (string * string)) option)

let passwords_do_not_match =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false
