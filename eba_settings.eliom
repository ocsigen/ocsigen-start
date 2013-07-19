(* Copyright Charly Chevalier *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

module InBox = struct
  let default_content () = Lwt.return []

  let create content = Lwt.return (D.div content)
end

module M = Eba_box.Make(InBox)

let add_item f =
  M.add_item f


let create () =
  let button =
    D.div ~a:[a_class ["eba_settings_button"]]
                 [D.i ~a:[a_class ["icon-gear"]] []]
  in
  lwt content = M.create () in
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
                Lwt.return [(%content :> Html5_types.div_content F.elt)]

            end)
  }});
  Lwt.return (button)
