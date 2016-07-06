
module type S = sig
  type key
  type notification
  val equal_key : key -> key -> bool
end

module Make (A : S) = Eliom_notif.Make (struct
  include A
  type identity = int64 option
  [@@deriving eq]
  let get_identity = fun () ->
    Eba_current_user.Opt.get_current_userid () |> Lwt.return
  let max_ressource = 1000
  let max_identity_per_ressource = 10
end)
