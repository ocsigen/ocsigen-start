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
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo = ~%demo

let%server demo_popup =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-popup"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_popup = ~%demo_popup

let%server demo_rpc =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-rpc"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_rpc = ~%demo_rpc

let%server demo_ref =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-ref"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_ref = ~%demo_ref

let%server demo_spinner =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-spinner"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_spinner = ~%demo_spinner

let%server demo_pgocaml =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-pgocaml"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_pgocaml = ~%demo_pgocaml

let%server demo_users =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-users"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_users = ~%demo_users

let%server demo_links =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-links"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_links = ~%demo_links

let%server demo_i18n =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-i18n"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_i18n = ~%demo_i18n

let%server demo_tips =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-tips"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_tips = ~%demo_tips

let%server demo_carousel1 =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-carousel1"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_carousel1 = ~%demo_carousel1

let%server demo_carousel2 =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-carousel2"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_carousel2 = ~%demo_carousel2

let%server demo_carousel3 =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-carousel3"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_carousel3 = ~%demo_carousel3

let%server demo_tongue =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-tongue"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_tongue = ~%demo_tongue

let%server demo_calendar =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-calendar"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_calendar = ~%demo_calendar

let%server demo_timepicker =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-timepicker"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_timepicker = ~%demo_timepicker

let%server demo_notif =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-notif"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_notif = ~%demo_notif

let%server demo_react =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-react"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_react = ~%demo_react

let%server demo_pulltorefresh =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-pulltorefresh"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_pulltorefresh = ~%demo_pulltorefresh

let%server demo_cache =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-cache"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_cache = ~%demo_cache

let%server demo_pagetransition =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-pagetransition"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_pagetransition = ~%demo_pagetransition

let%server demo_forms =
  Eliom.Service.create ~path:(Eliom.Service.Path ["demo-forms"])
    ~meth:(Eliom.Service.Get Eliom.Parameter.unit) ()

let%client demo_forms = ~%demo_forms

let%server detail_page =
  Eliom.Service.create
    ~path:(Eliom.Service.Path ["demo-page-transition"; "detail"; ""])
    ~meth:(Eliom.Service.Get (Eliom.Parameter.int "page"))
    ()

let%client detail_page = ~%detail_page
