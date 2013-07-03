(** this module is split on the two sides because we use it in the client side
  * with a Ew_buh.alert to show the settings box. So, we have to put all the
  * generators on the client side to let Ew_buh.alert generate the settings
  * box, using the generators *)

(** NOTE: we don't want to use the generators on the server side, because of
  * Ew_buh.alert. If had done this on the server side, we could not have use
  * the generators with Ew_buh.alert, because the content is generated at
  * runtime and so, the client side would have not known the final value of
  * the settings box. *)
{client{

  (** call the function of the Ol_holder functor *)
  val push_generator
    :
    (unit -> Html5_types.div_content Eliom_content.Html5.D.elt list) ->
    unit

}}

(** returns the button which can be used to trigger an Ew_buh.alert. It
  * also create a Ew_buh.alert and define the get_node method. This method
  * will call the create function of the Ol_holder functor (see
  * Ol_settings.eliom). *)
val create : unit -> Html5_types.div_content_fun Eliom_content.Html5.D.elt
