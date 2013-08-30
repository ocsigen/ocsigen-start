include Eba_main.App(
struct
  include Eba_default.App

  let app_name = "foobar"

  type notice_t = [ Eba_types.notice_t ] deriving (Json)
  type error_t = [ Eba_types.error_t ] deriving (Json)
  type state_t = [ Eba_types.state_t ] deriving (Json)

  let states =
    Eba_default.App.states
    @ []

  let page_config = object(self)
    inherit Eba_default.page_config ()

    method title = "foobar"

    method css = [
      ["eba.css"];
      ["eba_admin.css"];
      ["font-awesome.css"];
      ["foobar.css"]
    ]

    method js = [
      ["jquery-ui.min.js"];
      ["accents.js"];
      ["unix.js"]
    ]
  end
end)
