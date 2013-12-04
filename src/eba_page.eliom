{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

module Make(C : Eba_config.Page)(Session : Eba_sigs.Session) = struct

  exception Predicate_failed of (exn option)
  exception Not_connected = Session.Not_connected
  exception Permission_denied = Session.Permission_denied

  type page = Eba_shared.Page.page
  type page_content = Eba_shared.Page.page_content

  module Session = Session

  let css =
    List.map
      (fun cssname -> ("css"::cssname))
      (C.config#css)

  let js =
    List.map
      (fun jsname -> ("js"::jsname))
      (C.config#js)

  let page
      ?(predicate = C.config#default_predicate)
      ?(fallback = C.config#default_error_page)
      f gp pp =
    lwt content =
      try_lwt
        lwt b = predicate gp pp in
        if b then
          try_lwt f gp pp
          with exc -> fallback gp pp (exc)
        else fallback gp pp (Predicate_failed None)
      with exc -> fallback gp pp (Predicate_failed (Some exc))
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
      let uid' = ref (Int64.of_int 0) in
      let f_wrapped uid gp pp =
        uid' := uid;
        try_lwt
          lwt b = predicate uid gp pp in
          if b then
            try_lwt f uid gp pp
            with exc -> fallback uid gp pp (exc)
          else raise (Predicate_failed None)
        with
          | (Predicate_failed _) as exc -> raise exc
          | exc -> raise (Predicate_failed (Some exc))
      in
      try_lwt Session.connected_fun ?allow ?deny f_wrapped gp pp
      with exc -> fallback !uid' gp pp exc
    in
    Lwt.return
      (html
         (Eliom_tools.F.head ~title:C.config#title ~css ~js ())
         (body content))
end
