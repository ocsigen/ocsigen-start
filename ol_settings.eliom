{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

{client{

module MH_base = struct
  type container_t = Html5_types.div Eliom_content.Html5.D.elt
  type container_content_t = Html5_types.div_content Eliom_content.Html5.D.elt

  let default_content () =
    [
      p [pcdata "This is your settings"];
    ]

  let create content = D.div content

end

module MH = Ol_holder.Make(MH_base)

let push_generator f =
  MH.push_generator f

}}

let create () =
  let button =
    D.div [D.i ~a:[a_class ["icon-gear"]] []]
  in
    ignore ({unit{
      ignore (object(self)
                inherit [_] Ew_buh.alert
                      ~button:(To_dom.of_div %button)
                      ()

                method get_node =
                  Lwt.return [MH.create ()]
              end)
    }});
    button

