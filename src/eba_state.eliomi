module Make
  (C : Eba_config.State)
  (App : Eba_sigs.App)
  : Eba_sigs.State
     with type state = C.t
