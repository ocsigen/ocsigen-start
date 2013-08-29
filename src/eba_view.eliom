{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

{client{
  module Helper = struct
    let on_click ?(prevent_default = false) elt f =
      Lwt_js_events.async
        (fun () ->
           Lwt_js_events.clicks (To_dom.of_element elt)
             (fun e _ ->
                lwt () = f () in
                if prevent_default then
                  (Dom.preventDefault e; Dom_html.stopPropagation e);
                Lwt.return ()))

    let box_on_click ?(cls = []) ?(allow_outer_click = false) ?set elt f =
      ignore (object(self)
        inherit Ew_button.alert
          ?set
          ~allow_outer_click
          ~class_:cls
          ~button:elt
          ()

        method get_node = f ()
        end)
  end
  module H = Helper

  let global_set = Ew_button.new_radio_set ()
}}

module Make(M : sig module User : Eba_user.T end) = struct
  module Form = Eba_form
  module F = Form

  module Image = Eba_image.Make(struct module User = M.User end)
  module I = Image
end
