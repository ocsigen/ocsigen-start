(* Copyright Charly Chevalier *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

(** this module is designed for extensible container of html elements
  * (like the settings box). You just push some functions which will
  * generate list of html element of type [Eliom_content.Html5.D.div_content
  * Eliom_content.Html5.D.elt]. These functions let you add some content on
  * a container which already contains a default content. *)

(** technically, this module is just an HOLDER of a functions list
  * and add some primitives to create a container and push items
  * into the functions list *)
module type In = sig
  (** return the default content for the container,
    * this content will be automatically use on the
    * creation of the container *)
  val default_content : unit -> Html5_types.div_content Eliom_content.Html5.D.elt list Lwt.t
  (** create the container *)
  val create : Html5_types.div_content Eliom_content.Html5.D.elt list -> Html5_types.div Eliom_content.Html5.D.elt Lwt.t
end

module type Out = sig
  (** this function will just add a generator to his list to call it
    * when creating the container and his content *)
  val push_generator : (unit -> Html5_types.div_content Eliom_content.Html5.D.elt list Lwt.t) -> unit

  (** create the container using the default content and the generator
    * list to create the container's content *)
  val create : unit -> Html5_types.div Eliom_content.Html5.D.elt Lwt.t
end

module Make : functor (M : In) -> Out
