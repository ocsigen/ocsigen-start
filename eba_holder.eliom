(* Copyright Charly Chevalier *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

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

module Make(M : In) = struct

  let fl = ref []

  let push_generator f =
    fl := !fl @ [f]

  let create () =
    lwt dc = M.default_content () in
    let aux content f =
      lwt ret = f () in
      Lwt.return (content @ ret)
    in
    lwt content = Lwt_list.fold_left_s aux dc !fl in
    M.create content

end
