(* Copyright Charly Chevalier *)

(** This module define a little extensible settings box for a user *)

(** Will add an item into the box, an item correspond to a function which will
  * return a list of [Html5_types.div_content Eliom_content.Html5.D.elt]. This
  * list will be added to the settings box at his creation *)
val add_item
  : (unit -> Html5_types.div_content Eliom_content.Html5.D.elt list Lwt.t)
  -> unit

(** Returns the button corresponding to the settings box. You have to click on
  * this element to deploy the settings box *)
val create : unit -> Html5_types.div_content_fun Eliom_content.Html5.D.elt Lwt.t
