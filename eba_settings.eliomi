(* Copyright Charly Chevalier *)

(** this module define a little extensible settings box for a user *)

(** call the function of the Eba_holder functor.
    Must be called only once for each item when starting the site. *)
val push_generator
  : (unit -> Html5_types.div_content Eliom_content.Html5.D.elt list Lwt.t)
  -> unit

(** returns the button which can be used to trigger an Ew_buh.alert. It
  * also create a Ew_buh.alert and define the get_node method. This method
  * will call the create function of the Eba_holder functor (see
  * Eba_settings.eliom). *)
val create : unit -> Html5_types.div_content_fun Eliom_content.Html5.D.elt Lwt.t
