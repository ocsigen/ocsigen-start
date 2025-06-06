open%shared Lwt.Syntax

[%%shared
(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)
(* Eliom_cscache demo *)
open Eliom_content.Html.F]

(* Page for this demo *)
let%shared page () =
  Lwt.return
    [ h1 [%i18n Demo.cache_1]
    ; p
        [%i18n
          Demo.cache_2
            ~eliom_cscache:[code [txt "Eliom_cscache"]]
            ~os_user_proxy:[code [txt "Os_user_proxy"]]]
    ; p [%i18n Demo.cache_3 ~eliom_cscache:[code [txt "Eliom_cscache"]]]
    ; p [%i18n Demo.cache_4 ~eliom_cscache:[code [txt "Eliom_cscache"]]] ]

(* Service registration is done on both sides (shared section),
   so that pages can be generated from the server
   (first request, crawling, search engines ...)
   or the client (subsequent link clicks, or mobile app ...). *)
let%shared () =
  %%%MODULE_NAME%%%_base.App.register ~service:Demo_services.demo_cache
    ( %%%MODULE_NAME%%%_page.Opt.connected_page @@ fun myid_o () () ->
      let* p = page () in
      %%%MODULE_NAME%%%_container.page ~a:[a_class ["os-page-demo-cache"]] myid_o p )
