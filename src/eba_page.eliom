{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

module Make(C : Eba_config.Page)(Session : Eba_sigs.Session) = struct

type page_content' = [
    Html5_types.body_content
] Eliom_content.Html5.elt list

  type page = Eba_shared.Page.page
  type page_content = Eba_shared.Page.page_content

  module Session = Session

  let css =
    List.map
      (fun cssname -> ("css"::cssname))
      ([["popup.css"];
        ["jcrop.css"];
        ["jquery.Jcrop.css"]]
      @ C.config#css)

  let js =
    List.map
      (fun jsname -> ("js"::jsname))
      ([["jquery.js"];
        ["jquery.Jcrop.js"];
        ["jquery.color.js"]]
      @ C.config#js)

  let page
      ?(predicate = C.config#default_predicate)
      ?(fallback = C.config#default_error_page)
      f gp pp =
    lwt b = predicate gp pp in
    lwt content =
      if b
      then
        try_lwt f gp pp
        with exc -> fallback gp pp (Some exc)
      else fallback gp pp None
    in
    Lwt.return
      (html
         (Eliom_tools.F.head ~title:C.config#title ~css ~js ())
         (body content))

  let connected_page
      ?allow ?deny
      ?(predicate = C.config#default_connected_predicate)
      ?(fallback = C.config#default_connected_error_page)
      f gp pp =
    lwt content =
      try_lwt
        let f_wrapped uid gp pp =
          lwt b = predicate uid gp pp in
          if b
          then
            try_lwt f uid gp pp
            with exc -> fallback uid gp pp (Some exc)
          else fallback uid gp pp None
        in
        Session.connected_fun ?allow ?deny f_wrapped gp pp
      with exc -> fallback (Int64.of_int (-1)) gp pp (Some exc)
      (* FIXME: is the -1 (uid) the best solution for non-connected user ?
       * If yes, this must be in the documentation *)
    in
    Lwt.return
      (html
         (Eliom_tools.F.head ~title:C.config#title ~css ~js ())
         (body content))

end
