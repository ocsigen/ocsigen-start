open Eba_shared.Page

module Make
  (C : Eba_config.Page)
  (Session : Eba_sigs.Session)
  : Eba_sigs.Page with module Session = Session
