{shared{
  open Eliom_content.Html5.F
  open Eliom_content.Html5
}}

let application_name = "%%%PROJECT_NAME%%%"

let () = Eba_db.init ~port:3000 ~database:"%%%PROJECT_NAME%%%" ()

module Email_ = struct
  include Eba_default.Email

  let mailer = "/usr/sbin/sendmail"
end

module Page_ = struct
  include Eba_default.Page

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

module Email = Eba_email.Make(Email_)
module Page = Eba_page.Make(Page_)
