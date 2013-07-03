(** this module is designed for extensible container of html elements
  * (like the settings box). You just push some functions which will
  * generate list of html element of type [container_content_t]. These
  * functions let you add some content on a container which already
  * contains a default content. *)

(** technically, this module is just an HOLDER of a functions list
  * and add some primitives to create a container and push items
  * into the functions list *)
{shared{

module type In = sig
  type container_t (** type of the container *)
  type container_content_t (** type of the content *)

  (** return the default content for the container,
    * this content will be automatically use on the
    * creation of the container *)
  val default_content : unit -> container_content_t list
  (** create the container *)
  val create : container_content_t list -> container_t
end

module type Out = sig
  type container_t (** type of the container *)
  type container_content_t (** type of the content *)

  (** this function will just add a generator to his list to call it
    * when creating the container and his content *)
  val push_generator : (unit -> container_content_t list) -> unit

  (** create the container using the default content and the generator
    * list to create the container's content *)
  val create : unit -> container_t
end

module Make : functor (M : In)
  -> Out with type container_t = M.container_t
          and type container_content_t = M.container_content_t

}}
