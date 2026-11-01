(* Entry point of your own executable, which links Ocsigen Server as a
   library and runs the application without a configuration file: the
   configuration is then the static one of %%%MODULE_NAME%%%_static_config. It is
   not used when the ocsigenserver command loads the application from
   %%%PROJECT_NAME%%%.conf. *)

let () =
  Ocsigen.Server.start
    [ Ocsigen.Server.host
        [Staticmod.run ~dir:"local/var/www/%%%PROJECT_NAME%%%" (); Eliom.App.run ()] ]
