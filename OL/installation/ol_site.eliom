(* this will create the default table if it doesn't exist
 * any other better suggestions ? FIXME *)
(* possible value for state: 0 = WIP, 1 = on production *)
type state_t =
  | WIP
  | Production

(** default state for the website is close (wip) *)
let state = Eliom_reference.eref
              ~scope:Eliom_common.site_scope
              ~persistent:"website_state"
              WIP

let set_state (s : state_t) =
  Eliom_reference.set state s

let get_state () =
  Eliom_reference.get state
