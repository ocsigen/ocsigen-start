
module Make (A : sig type key type notification end) = Eliom_notif.Make (struct

  include A

  type identity = int64 option

  let equal = ( = )

  let get_identity = Eba_current_user.Opt.get_current_userid

  let max_ressource = 1000

  let max_identity_per_ressource = 10

end)
