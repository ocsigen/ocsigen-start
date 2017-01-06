(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)

(* Os_current_user demo *)

[%%shared
  open Eliom_content.Html.F
]

(* Service for this demo *)
let%server service =
  Eliom_service.create
    ~path:(Eliom_service.Path ["demo-users"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

(* Make service available on the client *)
let%client service = ~%service

(* Name for demo menu *)
let%shared name () = [%i18n S.users]

(* Class for the page containing this demo (for internal use) *)
let%shared page_class = "os-page-demo-users"

let%shared display_user_name = function
  | None -> p [ pcdata "You are not connected." ]
  | Some user ->
    p [ pcdata "You are: "
      ; em [ pcdata (Os_user.fullname_of_user user) ]
      ]

let%shared display_user_id = function
  | None -> p [ pcdata "Log in to see the demo." ]
  | Some userid ->
    p [ pcdata "Your user id: "
      ; em [ pcdata (Int64.to_string userid) ]
      ]

(* Page for this demo *)
let%shared page () =
  (* We use the convention to use "myid" for the user id of currently
     connected user, and "userid" for all other user id.
     We recommend to follow this convention, to reduce the risk
     of mistaking an user for another.
     We use prefix "_o" for optional value.
  *)
  let myid_o = Os_current_user.Opt.get_current_userid () in
  let me_o = Os_current_user.Opt.get_current_user () in
  Lwt.return
    [ p [ pcdata "Module "
        ; code [ pcdata "Os_current_user" ]
        ; pcdata " allows to get information about the currently \
                  connected user (server or client side). "
        ]
    ; display_user_name me_o
    ; display_user_id myid_o
    ; p [ pcdata "These functions can be called either from server or \
                  client-side."
        ]
    ; p [ pcdata "Always get the current user id using module "
        ; code [ pcdata "Os_current_user" ]
        ; pcdata ". Never trust a client sending its own user id!" ]
    ]
