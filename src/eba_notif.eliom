
module Make (A : sig type key type notification end) = Eliom_notif.Make (struct
  type identity = int64 option
  [@@deriving eq]
  type key = A.key
  [@@deriving eq]
  type notification = A.notification
  let get_identity = fun () ->
    Eba_current_user.Opt.get_current_userid |> Lwt.return
  let max_ressource = 1000
  let max_identity_per_ressource = 10
end)
