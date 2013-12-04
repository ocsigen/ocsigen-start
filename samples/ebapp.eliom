{shared{
  open Eliom_content.Html5.F
  open Eliom_content.Html5
}}

include Eba_main.App(struct
  let app_name = "foobar"

  module Session = Eba_default.Session

  module State = struct
    include Eba_default.State

    type t =
      | Default

    let states =
      [
        (Default, "default", None)
      ]

    let default () =
      Default
  end

  module Email = struct
    include Eba_default.Email

    let config = object
      inherit Eba_default.Email.config ()

      method mailer = "/usr/sbin/sendmail"
    end
  end

  module Groups = struct
    type t = Foobar_groups.t

    let in_group = Foobar_groups.in_group
  end

  module Page = struct
    include Eba_default.Page

    let config = object
      inherit Eba_default.Page.config ()

      method title = "foobar"

      method css = [
        ["foobar.css"];
      ]

      method js = [
        ["onload.js"]
      ]

      method default_predicate : 'a 'b. 'a -> 'b -> bool Lwt.t
        = (fun _ _ -> Lwt.return true)

      method default_connected_predicate : 'a 'b. int64 -> 'a -> 'b -> bool Lwt.t
        = (fun _ _ _ -> Lwt.return true)

      method default_error_page : 'a 'b. 'a -> 'b -> exn -> Eba_shared.Page.page_content Lwt.t
        = (fun _ _ _ -> Lwt.return [])

      method default_connected_error_page : 'a 'b. int64 option -> 'a -> 'b -> exn -> Eba_shared.Page.page_content Lwt.t
        = (fun _ _ _ _ -> Lwt.return [])
    end
  end
end)
