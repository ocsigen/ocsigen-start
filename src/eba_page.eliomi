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
  (** Module doc *)

  module Session : Eba_session.T

  type page = page'
  type page_content = page_content'

  (** Generate a page visible for non-connected and connected user.
    * Use the [predicate] function if you have something to check
    * before the generation of the page. Note that, if you return
    * [false], the page will be generated using the [fallback]
    * function. *)
  val page :    ?predicate:('a -> 'b -> bool Lwt.t)
             -> ?fallback:('a -> 'b -> exn option -> page_content Lwt.t)
             -> ('a -> 'b -> page_content Lwt.t)
             -> 'a -> 'b
             -> page Lwt.t

  (** Generate a page only visible for connected user.
    * The arguments [allow] and [deny] represents groups to which
    * the user has belongs to them or not. If the user does not
    * respect these requirements, the [fallback] function will be
    * used.
    * The predicate has the same behaviour that the [page] one. *)
  val connected_page :    ?allow:Session.group list
                       -> ?deny:Session.group list
                       -> ?predicate:(int64 -> 'a -> 'b -> bool Lwt.t)
                       -> ?fallback:(int64 -> 'a -> 'b -> exn option -> page_content Lwt.t)
                       -> (int64 -> 'a -> 'b -> page_content Lwt.t)
                       -> 'a -> 'b
                       -> page Lwt.t
end

module Make
  (M : sig val config : config end)
  (Session : Eba_session.T)
  : T with module Session = Session
