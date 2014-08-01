{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}



module Page = struct
  let title = ""
  let js : string list list = []
  let css : string list list = []
  let other_head : Eba_shared.Page.head_content = []

  let err_page exn =
    let de = if Ocsigen_config.get_debugmode ()
             then [p [pcdata "Debug info: ";
                      em [pcdata (Printexc.to_string exn)]]]
             else []
    in
    let l = match exn with
      | Eba_shared.Session.Not_connected ->
        p [pcdata "You must be connected to see this page."]::de
      | _ -> de
    in
    Lwt.return [div ~a:[a_class ["errormsg"]] (h2 [pcdata "Error"]::l)]

  let default_predicate
      : 'a 'b. 'a -> 'b -> bool Lwt.t
      = (fun _ _ -> Lwt.return true)

  let default_connected_predicate
      : 'a 'b. int64 -> 'a -> 'b -> bool Lwt.t
      = (fun _ _ _ -> Lwt.return true)

  let default_error_page
      : 'a 'b. 'a -> 'b -> exn -> Eba_shared.Page.page_content Lwt.t
      = (fun _ _ exn -> err_page exn)

  let default_connected_error_page
      : 'a 'b. int64 option -> 'a -> 'b -> exn
    -> Eba_shared.Page.page_content Lwt.t
      = (fun _ _ _ exn -> err_page exn)

end

module Session = struct
  let on_request = Lwt.return ()
  let on_denied_request (_ : int64) = Lwt.return ()
  let on_connected_request (_ : int64) = Lwt.return ()
  let on_open_session (_ : int64) = Lwt.return ()
  let on_close_session = Lwt.return ()
  let on_start_process = Lwt.return ()
  let on_start_connected_process (_ : int64) = Lwt.return ()
end

module Email = struct
  let from_addr =
      ("team DEFAULT", "noreply@DEFAULT.DEFAULT")

  let mailer = "/usr/bin/sendmail"
end

module State = struct
end

module App = struct
  module Page = Page
  module Session = Session
  module Email = Email
end
