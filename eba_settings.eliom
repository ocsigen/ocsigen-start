(* Copyright Charly Chevalier *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

module MH_base = struct
  let default_content () = Lwt.return []

  let create content = Lwt.return (D.div content)

end

module MH = Eba_holder.Make(MH_base)

let push_generator f =
  MH.push_generator f


let create () =
  let button =
    D.div ~a:[a_class ["eba_settings_button"]]
                 [D.i ~a:[a_class ["icon-gear"]] []]
  in
  lwt content = MH.create () in
  ignore ({unit{
    ignore (object(self)
              inherit [_] Ew_buh.alert
                ~set:Eba_site_widgets.settings_set
                ~class_:["eba_settings"]
                ~button:(To_dom.of_div %button)
                ()

              method get_node =
                Lwt.return [%content]
            end)
  }});
  Lwt.return (button)
