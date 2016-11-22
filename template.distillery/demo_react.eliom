(* page for this demo *)
let%server service =
  Eliom_service.create
    ~path:(Eliom_service.Path ["demo-react"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

(* make service available on the client (for mobile app) *)
let%client service = ~%service

(* name for demo menu *)
let%shared name = "Reactive programming"

(* class for the page containing this demo (for internal use) *)
let%shared page_class = "os-page-demo-react"

(* reactive list, initially empty *)
let%shared l, h = Eliom_shared.ReactiveData.RList.create []

(* make a text input field that calls [f s] for each [s] submitted *)
let%shared input msg f =
  let inp = Eliom_content.Html.D.Raw.input ()
  and btn = Eliom_content.Html.(
    D.button ~a:[D.a_class ["button"]] [D.pcdata msg]
  ) in
  ignore [%client
    ((Lwt.async @@ fun () ->
      let btn = Eliom_content.Html.To_dom.of_element ~%btn
      and inp = Eliom_content.Html.To_dom.of_input ~%inp in
      Lwt_js_events.clicks btn @@ fun _ _ ->
      let v = Js.to_string inp##.value in
      let%lwt () = ~%f v in
      inp##.value := Js.string "";
      Lwt.return ())
     : unit)
  ];
  Eliom_content.Html.D.div [inp; btn]

(* page for this demo *)
let%shared page () =
  let inp =
    (* form that performs a cons *)
    input "add"
      [%client
        ((fun v -> Lwt.return (Eliom_shared.ReactiveData.RList.cons v ~%h))
         : string -> unit Lwt.t)
      ]
  and l =
    (* produce <li> items from l contents *)
    Eliom_shared.ReactiveData.RList.map
      [%shared
        ((fun s -> Eliom_content.Html.(
           D.li [D.pcdata s]
         )) : _ -> _)
      ]
      l
  in
  Lwt.return Eliom_content.Html.[
    D.p [D.pcdata "This page demonstrates a reactive list. \
                   You can add elements via the input form"];
    inp;
    D.div [R.ul l]
  ]
