{shared{
  open Eliom_content.Html5.F
  open Eliom_content.Html5
}}

let application_name = "%%%PROJECT_NAME%%%"

let () = Eba_db.init ~port:3000 ~database:"%%%PROJECT_NAME%%%" ()

let () = Eba_email.set_mailer "/usr/sbin/sendmail"

module Page_config = struct
  include Eba_page.Default_config

  let title = "%%%PROJECT_NAME%%%"

  let css = [
    ["font-awesome.css"];
    ["jquery.Jcrop.css"];
    ["eba.css"];
    ["%%%PROJECT_NAME%%%.css"];
  ]

  let js = [
    ["onload.js"];
    ["jquery.js"];
    ["jquery.Jcrop.js"]
  ]

  let default_predicate _ _ = Lwt.return true

  let default_connected_predicate _ _ _ = Lwt.return true

  let default_error_page _ _ exn =
    Lwt.return (if Ocsigen_config.get_debugmode ()
                then [p [pcdata (Printexc.to_string exn)]]
                else [p [pcdata "Error"]])

  let default_connected_error_page _ _ _ exn =
    Lwt.return (if Ocsigen_config.get_debugmode ()
                then [p [pcdata (Printexc.to_string exn)]]
                else [p [pcdata "Error"]])
end



module App = Eliom_registration.App(struct
    let application_name = application_name
  end)

module Page = Eba_page.Make(Page_config)
