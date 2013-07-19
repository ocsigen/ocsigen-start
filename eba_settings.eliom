(* Copyright Charly Chevalier *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

let content : Html5_types.div_content F.elt list ref = ref []

let set_content cn = content := cn

let get_content () = !content

let get () =
  let button =
    D.div ~a:[a_class ["eba_settings_button"]]
                 [D.i ~a:[a_class ["icon-gear"]] []]
  in
  let content = !content in
  ignore ({unit{
    ignore (object(self)
              inherit Ew_button.alert
                ~set:Eba_site_widgets.settings_set
                ~class_:["eba_settings"]
                ~button:%button
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
  button
