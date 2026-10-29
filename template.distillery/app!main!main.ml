(* Entry point of the standalone executable, which runs the application
   without a configuration file: the configuration is then the static one
   of %%%MODULE_NAME%%%_static_config. It is not used when the application is
   loaded by ocsigenserver from %%%PROJECT_NAME%%%.conf. *)

let () =
  Ocsigen.Server.start
    [ Ocsigen.Server.host
        [Staticmod.run ~dir:"local/var/www/%%%PROJECT_NAME%%%" (); Eliom.App.run ()] ]
