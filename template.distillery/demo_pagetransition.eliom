[%%shared
  open Eliom_content
  open Html
  open Html.D
]

(* Service for this demo *)
let%server service =
  Eliom_service.create
    ~path:(Eliom_service.Path ["demo-page-transition" ; ""])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

let%server detail_page_service =
  Eliom_service.create
    ~path:(Eliom_service.Path ["demo-page-transition" ; "detail"; ""])
    ~meth:(Eliom_service.Get (Eliom_parameter.int "page"))
    ()

(* Make service available on the client *)
let%client service = ~%service

let%client detail_page_service = ~%detail_page_service

(* Name for demo menu *)
let%shared name () = [%i18n S.demo_pagetransition]

(* Class for the page containing this demo (for internal use) *)
let%shared page_class = "os-page-demo-transition"

[%%client 
  let split uri =
    match (Url.url_of_string uri) with
    | Some (Url.Http url) | Some (Url.Https url) -> 
      url.Url.hu_host,url.Url.hu_port,url.Url.hu_path
    | Some (Url.File url) -> "",0,url.Url.fu_path
    | None -> raise (Invalid_argument "incorrect url")

  let is_subpage_ path1 path2 =
    let rec aux = function
      | [],[] -> false
      | [],_::_ -> true
      | x1::s1,x2::s2 -> x1 = "" || (x1=x2 && aux (s1,s2))
      | _ -> false
    in aux (path1,path2)

  (*if uri2 refers to a subpage of the page represented by uri1*)
  let is_subpage uri1 uri2 =
    try
      let host1,port1,path1 = split uri1 in
      let host2,port2,path2 = split uri2 in
      host1 = host2 && port1 = port2 && is_subpage_ path1 path2
    with _ -> false

  let animation_type
      {Eliom_client.in_cache; 
       current_uri;
       target_uri;
       current_id;
       target_id} = 
    let target_id =
      match target_id with
      | None -> -1
      | Some id -> id in
    let back = target_id > 0 && target_id < current_id in
    let has_animation = 
      (back && is_subpage target_uri current_uri)
      || (not back && (is_subpage current_uri target_uri) && in_cache) in
    match has_animation,back with
    | false, _ -> Ot_page_transition.Nil
    | true, true -> Ot_page_transition.Backward
    | true, false -> Ot_page_transition.Forward

  let () =
    let take_screenshot ocaml_call_back =
      let call_back error response =
        match error with
        | None -> 
          let uri = (Cordova_plugin_screenshot.Response_uri.uri response) in
          ocaml_call_back uri
        | Some e -> Firebug.console##log (Js.string e) in
      Cordova_plugin_screenshot.uri_sync ~callback:call_back ~quality:100 ()
    in
    Ot_page_transition.install_global_handler_withURI
      ~transition_duration:0.4
      ~take_screenshot
      ~animation_type
]

let%shared create_item index =
  F.(li 
       ~a:[a_class ["demo-list-item";
                    Printf.sprintf "demo-list-item-%d" (index mod 5)]] 
       [a ~service:detail_page_service 
          [pcdata (Printf.sprintf "list%d" index)] index]) 

let%shared page () =  
  let l = (fun i -> create_item (i+1))
          |> Array.init 10
          |> Array.to_list 
          |> ul ~a:[a_class ["demo-list"]]
  in
  let add_button = 
    div ~a:[a_class ["demo-button"]] 
      [%i18n demo_pagetransition_add_button] in
  ignore 
    ([%client 
      ( Eliom_client.onload Eliom_client.push_history_dom;
        let counter = 
          let r = ref 10 in
          fun () -> r := !r +1 ; !r in
        Lwt_js_events.clicks 
          (To_dom.of_element ~%add_button)
          (fun _ _ -> 
             Html.Manip.appendChild ~%l (create_item (counter ()));
             Lwt.return_unit ):unit Lwt.t)]) ;
  Lwt.return (
    [ h1 [%i18n demo_pagetransition_list_page]
    ;l
    ;add_button]
  )

let%shared make_detail_page page () =
  let back_button = 
    div ~a:[a_class ["demo-button"]] 
      [%i18n demo_pagetransition_back_button] in
  ignore ([%client (
    Lwt.async (fun () ->
      Lwt_js_events.clicks 
        (To_dom.of_element ~%back_button)
        (fun _ _ -> 
           Dom_html.window##.history##back;
           Lwt.return_unit )):unit)]);
  [h1 ([%i18n demo_pagetransition_detail_page] 
       @ [pcdata (Printf.sprintf " %d" page)]);
   back_button]
