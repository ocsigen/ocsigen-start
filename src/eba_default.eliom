{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

class page_config () : Eba_page.config = object
  method title = "app"
  method js : string list list = []
  method css : string list list = []

  method default_error_page
    : 'a 'b. 'a -> 'b ->
      [Html5_types.body_content] Eliom_content.Html5.elt list Lwt.t =
    (fun _ _ -> Lwt.return [D.div [p [pcdata "error"]]])

  method default_error_connected_page (_:int64) gp pp : [Html5_types.body_content] Eliom_content.Html5.elt list Lwt.t =
    Lwt.return [D.div [p [pcdata "error"]]]

end

class session_config () = object
  method on_open_session = Lwt.return ()
  method on_close_session = Lwt.return ()
  method on_start_process = Lwt.return ()
  method on_start_connected_process = Lwt.return ()
end

class db_config () = object
  method name = "eba"
  method port = 5432
  method workers = 16

  method hash s =
    Bcrypt.string_of_hash (Bcrypt.hash s)

  method verify s1 s2 =
    Bcrypt.verify s1 (Bcrypt.hash_of_string s2)
end

class mail_config () = object
  method from_addr app_name =
    (app_name^" team", "noreply@ocsigenlabs.com")

  method to_addr (mail : string) =
    ("", mail)
end

module App = struct
  let db_config = new db_config ()
  let session_config = new session_config ()
  let page_config : Eba_page.config = new page_config ()
  let mail_config = new mail_config ()

  let states = [
    (`Normal, "Normal", Some "allow you to register users");
    (`Restricted, "Restricted", Some "allow you to pre-register (not register) users");
  ]
end
