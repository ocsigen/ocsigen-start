{shared{

module type In = sig
  type container_t
  type container_content_t

  val default_content : unit -> container_content_t list
  val create : container_content_t list -> container_t
end

module type Out = sig
  type container_t
  type container_content_t

  val push_generator : (unit -> container_content_t list) -> unit
  val create : unit -> container_t
end

module Make(M : In) = struct

  type container_t = M.container_t
  type container_content_t = M.container_content_t

  let fl = ref []

  let push_generator f =
    fl := !fl @ [f]

  let create () =
    M.create
      (List.fold_left
         (fun content f -> content @ (f ()))
         (M.default_content ())
         (!fl))

end

}}
