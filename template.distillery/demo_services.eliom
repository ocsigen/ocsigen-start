(* Services for each demo page *)

(* Services are defined in this module for dependency reasons:
   Each page contains a menu, with links towards each service.
*)

(* Services are first defined in the server-side app,
   then the client-side value is defined as injections.
   Services cannot usually be created in shared sections
   as some random identifiers must be the same on both sides.
*)

let%server demo =
  Eliom_service.create ~path:(Eliom_service.Path ["demo"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo = ~%demo

let%server demo_rpc =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-rpc"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_rpc = ~%demo_rpc

let%server demo_ref =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-ref"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_ref = ~%demo_ref

let%server demo_spinner =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-spinner"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_spinner = ~%demo_spinner

let%server demo_pgocaml =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-pgocaml"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_pgocaml = ~%demo_pgocaml

let%server demo_users =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-users"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_users = ~%demo_users

let%server demo_links =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-links"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_links = ~%demo_links

let%server demo_i18n =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-i18n"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_i18n = ~%demo_i18n

let%server demo_popup =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-popup"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_popup = ~%demo_popup

let%server demo_tips =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-tips"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_tips = ~%demo_tips

let%server demo_carousel1 =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-carousel1"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_carousel1 = ~%demo_carousel1

let%server demo_carousel2 =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-carousel2"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_carousel2 = ~%demo_carousel2

let%server demo_carousel3 =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-carousel3"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_carousel3 = ~%demo_carousel3

let%server demo_tongue =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-tongue"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_tongue = ~%demo_tongue

let%server demo_calendar =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-calendar"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_calendar = ~%demo_calendar

let%server demo_timepicker =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-timepicker"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_timepicker = ~%demo_timepicker

let%server demo_notif =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-notif"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_notif = ~%demo_notif

let%server demo_react =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-react"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_react = ~%demo_react

let%server demo_pulltorefresh =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-pulltorefresh"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_pulltorefresh = ~%demo_pulltorefresh

let%server demo_cache =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-cache"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_cache = ~%demo_cache

let%server demo_pagetransition =
  Eliom_service.create ~path:(Eliom_service.Path ["demo-pagetransition"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit) ()

let%client demo_pagetransition = ~%demo_pagetransition

let%server detail_page =
  Eliom_service.create
    ~path:(Eliom_service.Path ["demo-page-transition"; "detail"; ""])
    ~meth:(Eliom_service.Get (Eliom_parameter.int "page"))
    ()

let%client detail_page = ~%detail_page
