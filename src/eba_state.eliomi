module Make
  (C : Eba_config.State)
  (App : Eliom_registration.ELIOM_APPL)
  : Eba_sigs.State
     with type state = C.t
