(* Copyright Charly Chevalier *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

module type In = sig
  val default_content : unit -> Html5_types.div_content Eliom_content.Html5.D.elt list Lwt.t
  val create : Html5_types.div_content Eliom_content.Html5.D.elt list -> Html5_types.div Eliom_content.Html5.D.elt Lwt.t
end

module Make(M : In) = struct

  let fl = ref []

  let add_item f =
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
