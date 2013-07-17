(* Copyright Charly Chevalier *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

(** This module is designed for extensible container of html elements
  * (like the settings box). You just add some functions which will
  * generate list of html element of type [Eliom_content.Html5.D.div_content
  * Eliom_content.Html5.D.elt]. These functions let you add some content on
  * a container which already contains a default content. *)
module type In = sig
  (** Return the default content for the container,
    * this content will be automatically use on the
    * creation of the container *)
  val default_content
    : unit
    -> Html5_types.div_content Eliom_content.Html5.D.elt list Lwt.t

  (** Create the container *)
  val create
    : Html5_types.div_content Eliom_content.Html5.D.elt list
    -> Html5_types.div Eliom_content.Html5.D.elt Lwt.t
end

module Make : functor (M : In) -> sig
  (** Add an item into the box, an item correspond to a function which will
    * return a list of [Html5_types.div_content Eliom_content.Html5.D.elt].
    * This list will be added to the box at his creation *)
  val add_item : (unit -> Html5_types.div_content Eliom_content.Html5.D.elt list Lwt.t) -> unit

  (** Create the container using the default content and the list of functions
    * to create the container's content *)
  val create : unit -> Html5_types.div Eliom_content.Html5.D.elt Lwt.t
end
