{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

type page' = [
    Html5_types.html
] Eliom_content.Html5.elt

type page_content' = [
    Html5_types.body_content
] Eliom_content.Html5.elt list

class type config = object
  method title : string
  method js : string list list
  method css : string list list

  method default_error_page :
    'a 'b. 'a -> 'b -> exn option -> page_content' Lwt.t
  method default_connected_error_page :
    'a 'b. int64 -> 'a -> 'b -> exn option -> page_content' Lwt.t

  method default_predicate :
    'a 'b. 'a -> 'b -> bool Lwt.t
  method default_connected_predicate :
    'a 'b. int64 -> 'a -> 'b -> bool Lwt.t
end

module type T = sig
  module Session : Eba_session.T

  type page = page'
  type page_content = page_content'

  val page :
       ?predicate:('a -> 'b -> bool Lwt.t)
    -> ?fallback:('a -> 'b -> exn option -> page_content Lwt.t)
    -> ('a -> 'b -> page_content Lwt.t)
    -> 'a -> 'b
    -> page Lwt.t

  val connected_page :
       ?allow:Session.group list
    -> ?deny:Session.group list
    -> ?predicate:(int64 -> 'a -> 'b -> bool Lwt.t)
    -> ?fallback:(int64 -> 'a -> 'b -> exn option -> page_content Lwt.t)
    -> (int64 -> 'a -> 'b -> page_content Lwt.t)
    -> 'a -> 'b
    -> page Lwt.t
end

module Make(M : sig val config : config end)(Session : Eba_session.T) = struct

  type page = page'
  type page_content = page_content'

  module Session = Session

  let css =
    List.map
      (fun cssname -> ("css"::cssname))
      ([["popup.css"];
        ["jcrop.css"];
        ["jquery.Jcrop.css"]]
      @ M.config#css)

  let js =
    List.map
      (fun jsname -> ("js"::jsname))
      ([["jquery.js"];
        ["jquery.Jcrop.js"];
        ["jquery.color.js"]]
      @ M.config#js)

  let page
      ?(predicate = M.config#default_predicate)
      ?(fallback = M.config#default_error_page)
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
         (Eliom_tools.F.head ~title:M.config#title ~css ~js ())
         (body content))

  let connected_page
      ?allow ?deny
      ?(predicate = M.config#default_connected_predicate)
      ?(fallback = M.config#default_connected_error_page)
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
         (Eliom_tools.F.head ~title:M.config#title ~css ~js ())
         (body content))

end
