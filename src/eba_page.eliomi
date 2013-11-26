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
  (** Module doc *)

  (** Generate a page visible for non-connected and connected user.
    * Use the [predicate] function if you have something to check
    * before the generation of the page. Note that, if you return
    * [false], the page will be generated using the [fallback]
    * function. *)
  val page :    ?predicate:('a -> 'b -> bool Lwt.t)
             -> ?fallback:('a -> 'b -> exn option -> page_content_t Lwt.t)
             -> ('a -> 'b -> page_content_t Lwt.t)
             -> 'a -> 'b
             -> page_t Lwt.t

  (** Generate a page only visible for connected user.
    * The arguments [allow] and [deny] represents groups to which
    * the user has belongs to them or not. If the user does not
    * respect these requirements, the [fallback] function will be
    * used.
    * The predicate has the same behaviour that the [page] one. *)
  val connected_page :    ?allow:Eba_types.Groups.t list
                       -> ?deny:Eba_types.Groups.t list
                       -> ?predicate:(int64 -> 'a -> 'b -> bool Lwt.t)
                       -> ?fallback:(int64 -> 'a -> 'b -> exn option -> page_content_t Lwt.t)
                       -> (int64 -> 'a -> 'b -> page_content_t Lwt.t)
                       -> 'a -> 'b
                       -> page_t Lwt.t
end

module Make : functor(M :
sig
  val config : config
  module Session : Eba_session.T
end) -> T
