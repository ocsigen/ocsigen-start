[%%shared
    open Eliom_content.Html5
    open Eliom_content.Html5.D
]

[%%shared
module type DemoPage = sig
  val name : string
  val service :
    (unit, unit,
     Eliom_service.get,
     Eliom_service.att,
     Eliom_service.non_co,
     Eliom_service.non_ext,
     Eliom_service.reg,
     [ `WithoutSuffix ],
     unit, unit,
     Eliom_service.non_ocaml)
      Eliom_service.t
  val page : unit -> ([> `Input | `P | `Div] Eliom_content.Html5.D.elt) list
end
]

(* popup button demo **********************************************************)

[%%shared
module PopupPage : DemoPage = struct
  let name = "Popup Button"
  let service =
    Eliom_service.create
      ~id:(Eliom_service.Path ["otdemo-popup"])
      ~meth:(Eliom_service.Get Eliom_parameter.unit)
      ()
  let page () =
    let button = D.Form.input ~a:[a_class ["button"]] ~input_type:`Submit ~value:"Click for a popup!" (Form.string) in
    ignore
      [%client
        (Lwt.async (fun () ->
           Lwt_js_events.clicks
             (To_dom.of_element ~%button)
             (fun _ _ ->
                let%lwt _ =
                  Ot_popup.popup
                    ~close_button:[pcdata "close"]
                    (fun _ -> Lwt.return @@ p [pcdata "Popup message"])
                in
                Lwt.return ()))
         : _)
      ];
    [
      p [pcdata "Here is a button showing a simple popup window when clicked:"];
      p [button]
    ]
end
]

(* carousel demo **************************************************************)

let%client (carousel_update, carousel_change) = React.E.create ()

[%%shared
module CarouselPage : DemoPage = struct
  let name = "Carousel"
  let service =
    Eliom_service.create
      ~id:(Eliom_service.Path ["otdemo-carousel"])
      ~meth:(Eliom_service.Get Eliom_parameter.unit)
      ()
  let page () =
    let make_page content = div ~a:[a_class ["otdemo-carousel-page"]] [pcdata content] in
    let carousel_pages = ["1"; "2"; "3"] in
    let (carousel, pos, size) = Ot_carousel.make
      ~a:[a_class ["otdemo-carousel"]]
      ~update:[%client carousel_update]
      (List.map make_page carousel_pages)
    in
    let prev = Ot_carousel.previous
      ~a:[a_class ["button"]]
      ~change:[%client carousel_change]
      ~pos
      [pcdata "←"]
    in
    let next = Ot_carousel.next
      ~a:[a_class ["button"]]
      ~change:[%client carousel_change]
      ~pos
      ~length:(List.length carousel_pages)
      ~size
      [pcdata "→"]
    in
    let ribbon = Ot_carousel.ribbon
      ~change:[%client carousel_change]
      ~pos
      ~size
      (List.map (fun n -> [pcdata n]) carousel_pages)
    in
    [
      p [pcdata "The carousel displays a number of blocks side-by-side (or vertically stacked)."];
      p [pcdata "To switch to a different block, either use the buttons above or below the carousel."];
      p [pcdata "In the mobile app you can also swipe the screen."];
      ribbon; carousel; p [prev; next]
    ]
end
]

(* drawer / otdemo welcome page ***********************************************)

let%shared demos = [(module PopupPage : DemoPage); (module CarouselPage)]

(* adds a drawer menu to the document body *)
let%shared make_drawer_menu () =
  let menu =
    let make_link (module D : DemoPage) = li [a ~service:D.service [pcdata @@ D.name] ()] in
    let menu = ul (List.map make_link demos) in
    [div ~a:[a_class ["eba-drawer"]] [h3 [pcdata "otdemo: drawer menu"]; menu]]
  in
  let (drawer, open_drawer, close_drawer) = Ot_drawer.drawer menu in
  ignore [%client (Eliom_content.Html5.Manip.appendToBody ~%drawer : _)];
  (open_drawer, close_drawer)
  (* let button = D.Form.input ~a:[a_class ["button"]] ~input_type:`Submit ~value:"Menu→" (Form.string) in *)
  (* ignore [%client (Lwt.async (fun () -> Lwt_js_events.clicks (To_dom.of_element ~%button) *)
  (*                        (fun ev _ -> ~%open_drawer (); Lwt.return ())) : _)]; *)
  (* div ~a:[a_class ["eba-drawer-button"]] [ *)

let%shared make_page userid_o content =
  %%%MODULE_NAME%%%_container.page userid_o (
    ignore (make_drawer_menu ());
    content ()
  )

let%shared handler userid_o () () = make_page userid_o @@
  fun () -> [
    p [pcdata "This page contains some demos for some widgets \
               from ocsigen-toolkit."];
    p [pcdata "The different demos are accessible through the drawer\
               menu. To open it click the top left button on the screen."];
    p [pcdata "Feel free to modify the generated code and use it \
               or redistribute it as you want."];
  ]

let%server () =
  let demo_page content userid_o () () = make_page userid_o content in
  let registerDemo (module D : DemoPage) =  %%%MODULE_NAME%%%_base.App.register
    ~service:D.service
    (%%%MODULE_NAME%%%_page.Opt.connected_page @@ demo_page D.page)
  in List.iter registerDemo demos;
  %%%MODULE_NAME%%%_base.App.register
    ~service:%%%MODULE_NAME%%%_services.otdemo_service
    (%%%MODULE_NAME%%%_page.Opt.connected_page handler)
