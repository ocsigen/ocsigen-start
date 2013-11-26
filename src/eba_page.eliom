{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

type page_t = [Html5_types.html] Eliom_content.Html5.elt
type page_content_t = [Html5_types.body_content] Eliom_content.Html5.elt list

class type config = object
  method title : string
  method js : string list list
  method css : string list list
  method default_error_page :
    'a 'b. 'a -> 'b -> exn option -> page_content_t Lwt.t
  method default_connect_error_page :
    'a 'b. int64 -> 'a -> 'b -> exn option -> page_content_t Lwt.t
end

module type T = sig
  val page :    ?predicate:('a -> 'b -> bool Lwt.t)
             -> ?fallback:('a -> 'b -> exn option -> page_content_t Lwt.t)
             -> ('a -> 'b -> page_content_t Lwt.t)
             -> 'a -> 'b
             -> page_t Lwt.t

  val connected_page :    ?allow:Eba_types.Groups.t list
                       -> ?deny:Eba_types.Groups.t list
                       -> ?predicate:(int64 -> 'a -> 'b -> bool Lwt.t)
                       -> ?fallback:(int64 -> 'a -> 'b -> exn option -> page_content_t Lwt.t)
                       -> (int64 -> 'a -> 'b -> page_content_t Lwt.t)
                       -> 'a -> 'b
                       -> page_t Lwt.t
end

module Make(M : sig
  val config : config

  module Session : Eba_session.T
end)
=
struct

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
        ?(predicate = (fun _ _ -> Lwt.return true))
        ?(fallback = M.config#default_error_page)
        f gp pp
    =
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
        ?(predicate = (fun _ _ _ -> Lwt.return true))
        ?(fallback = M.config#default_connect_error_page)
        f gp pp
    =
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
        M.Session.connected_fun ?allow ?deny f_wrapped gp pp
      with exc -> fallback (Int64.of_int (-1)) gp pp (Some exc)
      (* FIXME: is the -1 (uid) the best solution for non-connected user ?
       * If yes, this must be in the documentation *)
    in
    Lwt.return
      (html
         (Eliom_tools.F.head ~title:M.config#title ~css ~js ())
         (body content))

end
