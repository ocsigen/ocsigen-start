{shared{
  type state_t =
    | Close
    | Open
        deriving (Json)
}}

(** default state for the website is open  *)
let state = Eliom_reference.eref
              ~scope:Eliom_common.site_scope
              ~persistent:"website_state"
              Open

let set_state (s : state_t) =
  Eliom_reference.set state s

let get_state () =
  Eliom_reference.get state
