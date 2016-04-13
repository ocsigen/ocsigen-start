let%server application_name = !%%%MODULE_NAME%%%_config.app_name

let%client application_name = Eliom_client.get_application_name ()

let getenv name default_value =
  try
    Sys.getenv name
  with Not_found ->
    default_value

let () =
  let int_of_pgport s =
    try
      int_of_string s
    with Failure _ ->
      failwith @@ Printf.sprintf
        "PGPORT environment variable must be an integer, not '%s'" s
  in
  Eba_db.init ()
    ~db_host:(getenv "PGHOST" "localhost")
    ~port:(int_of_pgport (getenv "PGPORT" "3000"))
    ~database:"%%%PROJECT_NAME%%%"

let () = Eba_email.set_mailer "/usr/sbin/sendmail"

module App = Eliom_registration.App(struct
    let application_name = application_name
  end)
