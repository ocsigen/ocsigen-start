include Eba_main.App(struct
  include Eba_default.App

  let app_name = "foobar"

  type notice_t = [ Eba_types.notice_t ] deriving (Json)
  type error_t = [ Eba_types.error_t ] deriving (Json)

  type state_t = [ Eba_types.state_t ] deriving (Json)

  let states =
    Eba_default.App.states
    @ []

  let email_config = object
    inherit Eba_default.email_config ()

    method mailer = "/usr/sbin/sendmail"
  end

  let page_config = object(self)
    inherit Eba_default.page_config ()

    method title = "foobar"

    method css = [
      ["foobar.css"];
    ]

    method js = [
      ["onload.js"]
    ]
  end

  module Database = Foobar_pgocaml
end)

include Foobar_pgocaml

{client{
  module User = struct
    include Eba_shared.User
  end
  module Groups = struct
    include Eba_shared.Groups
  end
}}
