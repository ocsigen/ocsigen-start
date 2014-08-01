{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

module Page = struct
  class config () = object
    method title = ""
    method js : string list list = []
    method css : string list list = []
    method other_head : Eba_shared.Page.head_content = []

    method default_predicate
      : 'a 'b. 'a -> 'b -> bool Lwt.t
      = (fun _ _ -> Lwt.return true)
    method default_connected_predicate
      : 'a 'b. int64 -> 'a -> 'b -> bool Lwt.t
      = (fun _ _ _ -> Lwt.return true)

    method default_error_page
      : 'a 'b. 'a -> 'b -> exn -> Eba_shared.Page.page_content Lwt.t
      = (fun _ _ _ -> Lwt.return [])
    method default_denied_page
      : 'a 'b. int64 option -> 'a -> 'b -> Eba_shared.Page.page_content  Lwt.t
      = (fun _ _ _ -> Lwt.return [])

    method default_connected_error_page
      : 'a 'b. int64 option -> 'a -> 'b -> exn -> Eba_shared.Page.page_content Lwt.t
      = (fun _ _ _ _ -> Lwt.return [])
  end

  let config = new config ()
end

module Session = struct
  class config () = object
    method on_request = Lwt.return ()
    method on_denied_request (_ : int64) = Lwt.return ()
    method on_connected_request (_ : int64) = Lwt.return ()
    method on_open_session (_ : int64) = Lwt.return ()
    method on_close_session = Lwt.return ()
    method on_start_process = Lwt.return ()
    method on_start_connected_process (_ : int64) = Lwt.return ()
  end

  let config = new config ()
end

module Email = struct
  class config () = object
    method from_addr =
      ("team DEFAULT", "noreply@DEFAULT.DEFAULT")

    method mailer = "/usr/bin/sendmail"
  end

  let config = new config ()
end

module State = struct
end

module App = struct
  module Page = Page
  module Session = Session
  module Email = Email
end
