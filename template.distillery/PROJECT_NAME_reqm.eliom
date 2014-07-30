open Eliom_content.Html5.F
open Printf

include Ebapp.Reqm

exception Ignored

let ignore_to_html _ = raise Ignored

let error_set = Ebapp.Reqm.create_set "error"
let notice_set = Ebapp.Reqm.create_set "notice"

let to_error_box s =
  div ~a:[a_class ["error"]] [
    pcdata s
  ]

let to_notice_box s =
  div ~a:[a_class ["notice"]] [
    pcdata s
  ]

let notice_string s =
  ignore (Ebapp.Reqm.create
            ~set:notice_set
            ~to_html:(to_notice_box)
            ~default:(fun () -> s)
            ())

let error_string s =
  ignore (Ebapp.Reqm.create
            ~set:error_set
            ~to_html:(to_error_box)
            ~default:(fun () -> s)
            ())

let wrong_pdata =
  Ebapp.Reqm.create
    ~to_html:ignore_to_html
    ~cons:(cons : ((string * string) * (string * string)) cons)
    ()


(*VVV Do we want to use Eba_reqm for this? *)
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
