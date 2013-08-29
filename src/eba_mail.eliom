class type config = object
  method from_addr : string -> (string * string)
  method to_addr : string -> (string * string)
end

module type T = sig
  val app_name : string
  val config : config

  module Rmsg : Eba_rmsg.T
end

module Make(M : T) = struct
  let send ?(from_addr = M.config#from_addr M.app_name) ~to_addrs ~subject f =
    (* TODO with fork ou mieux en utilisant l'event loop de ocamlnet *)
    try_lwt
      let open Netsendmail in
      lwt content = f M.app_name in
      let content =
        List.fold_left
          (fun s1 s2 -> s1^"\n"^s2)
          ("") (content)
      in
      let to_addrs = List.map (M.config#to_addr) to_addrs in
      sendmail (compose ~from_addr ~to_addrs ~subject content);
      Lwt.return true
    with
      | _ -> (* TODO: get informations from exception and forward them into
              * `Send_mail_failed rmsg *)
          M.Rmsg.Error.push `Send_mail_failed;
          Lwt.return false
end
