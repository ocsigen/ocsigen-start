(* Copyright Vincent Balat, Charly Chevalier *)

(** This functor provides a cache system which is reset for each
  * requests. You have to provide a minimal configuration module
  * to indicate which type used for the [key_t] and [value_t]
  * which are used to store data in the cache. Also, you have
  * to provide a comparison function and a function which get
  * the corresponding value for a key. *)

module type In = sig
  type key_t (** type for the key in the cache map *)
  type value_t (** type for the value in the cache map *)

  (** comparison function (needed by the map) *)
  val compare : key_t -> key_t -> int

  (** returns the corresponding value for a key *)
  val get : key_t -> value_t Lwt.t
end

module Make : functor (M : In) -> sig

  (** Returns the corresponding value for a key, using the cache
    * if the value has been already retrieved, otherwise, it will call
    * the get function of the configuration module to get the corresponding
    * value and to store it into the map *)
  val get : M.key_t -> M.value_t Lwt.t

  (** Use this function if you have a function which alterate the value
    * of type [value_t] to be sure that the data on the cache will be update
    * on the next call of get function *)
  val wrap_function : M.key_t -> (unit -> M.value_t Lwt.t) -> M.value_t Lwt.t
end

