(* Copyright Charly Chevalier *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

let content
    : (Eba_user.shared_t -> Html5_types.div_content F.elt list Lwt.t) ref =
  ref (fun _ -> Lwt.return [])

let set_content cn = content := cn

let get_content () = !content

let create_box user =
  let button =
    D.div ~a:[a_class ["eba_settings_button"]]
                 [D.i ~a:[a_class ["icon-gear"]] []]
  in
  lwt content = get_content () user in
  ignore ({unit{
    ignore (object(self)
              inherit Ew_button.alert
                ~class_:["eba_settings"]
                ~set:Eba_site_widgets.global_widget_set
                ~button:%button
                ~allow_outer_click:false
                ()

              (* get_node returns div_content type, so we have to
               * coerce to this type, even if div type could be
               * into another div. I don't really understand this
               * coercion.. *)
              method get_node =
                let open Eliom_content.Html5 in
                Lwt.return (%content)

            end)
  }});
  Lwt.return button
