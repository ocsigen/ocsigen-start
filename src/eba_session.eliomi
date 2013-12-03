(* Copyright Vincent Balat, Charly Chevalier *)

module Make
  (C : Eba_config.Session)
  (Groups : Eba_sigs.Groups)
  : Eba_sigs.Session with type group = Groups.t
