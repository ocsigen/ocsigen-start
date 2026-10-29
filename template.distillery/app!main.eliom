(* Entry module of the application on both sides. The code of the
   application is in the library %%%MODULE_NAME%%% (lib/); this module only links
   it. The server part is loaded by ocsigenserver from %%%PROJECT_NAME%%%.conf or
   run by the standalone executable (app/main/). The client part is the main
   module of the client program. *)

module%shared %%%MODULE_NAME%%% = %%%MODULE_NAME%%%
