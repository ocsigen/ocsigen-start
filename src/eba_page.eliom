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
  method default_error_page : 'a 'b. 'a -> 'b -> page_content_t Lwt.t
  method default_error_connected_page : int64 -> unit -> unit -> page_content_t Lwt.t
end

module type T = sig
  val page :    ?allow:Eba_types.Groups.t list
             -> ?deny:Eba_types.Groups.t list
             -> ?predicate:('a -> 'b -> bool Lwt.t)
             -> ?fallback:('a -> 'b -> page_content_t Lwt.t)
             -> (unit -> page_content_t Lwt.t)
             -> page_t Lwt.t

  val connected_page :    ?allow:Eba_types.Groups.t list
                       -> ?deny:Eba_types.Groups.t list
                       -> ?predicate:(int64 -> 'a -> 'b -> bool Lwt.t)
                       -> ?fallback:('a -> 'b -> page_content_t Lwt.t)
                       -> ?connected_fallback:(int64 -> 'a -> 'b -> page_content_t Lwt.t)
                       -> (int64 -> page_content_t Lwt.t)
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
      then f gp pp
      else fallback gp pp
    in
    Lwt.return
      (html
         (Eliom_tools.F.head ~title:M.config#title ~css ~js ())
         (body content))

  let connected_page
        ?allow ?deny
        ?(predicate = (fun _ _ _ -> Lwt.return true))
        ?(fallback = M.config#default_error_page)
        ?(connected_fallback = M.config#default_error_connected_page)
        f gp pp
    =
    lwt content =
      try_lwt
        let f_wrapped uid gp pp =
          lwt b = predicate uid gp pp in
          if b
          then f uid gp pp
          else connected_fallback uid gp pp
        in
        M.Session.connect_wrapper_function ?allow ?deny f_wrapped gp pp
      with Eba_shared.Session.Not_connected -> fallback gp pp
    in
    Lwt.return
      (html
         (Eliom_tools.F.head ~title:M.config#title ~css ~js ())
         (body content))

end
