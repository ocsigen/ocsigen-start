(* Copyright Séverine Maingaud *)

{shared{
open Eliom_content.Html5
open Eliom_content.Html5.F

let cls_widget = "ol_selector_widget"
let cls_send = "ol_sw_sendbutton"
let cls_cancel = "ol_sw_cancelbutton"
let cls_buttons = "ol_sw_buttons"
let cls_removebutton = "ol_sw_removebutton"
let cls_selected = "ol_sw_selected"
let cls_tbox = "ol_user_box"
let cls_completion_input = "ol_sw_completion_input"
}}


{shared{
(* Generic widget for selecting any kind of objets and using any kind of
   selection method. The selection of a list of objects is done during
   launch_selector is runnig. This function returns a reference to the
   list of selected objects wich is passed to the send_handler or droped. *)
let selector_widget ?(cls_widget=cls_widget) ?(cls_send=cls_send)
    ?(cls_cancel=cls_cancel) ?(cls_buttons=cls_buttons)
    ?(cls_selected=cls_selected) launch_selector send_handler me
    =
  let selector = D.span [] in
  let send_button = D.button ~a:[a_class [cls_send]]
    ~button_type:`Button [Icons.ok_circle] in
  let cancel_button = D.button  ~a: [a_class [cls_cancel]]
    ~button_type:`Button [Icons.remove_circle] in
  let buttons = D.div ~a:[a_class [cls_buttons]]
    [cancel_button ; send_button] in
  let container = D.div ~a:[a_class [cls_widget]] [selector ; buttons] in
  let _, the_input, selected_ref = launch_selector ~selector in

  ignore {unit{
    let selected_ref = %selected_ref in
    let send_button = To_dom.of_button %send_button in
    let cancel_button = To_dom.of_button %cancel_button in
    let open Lwt_js_events in

    async (fun () ->
      clicks send_button (fun ev _ ->
        lwt () = match !selected_ref with
          | [] -> Lwt.return ()
          | l -> %send_handler l
        in
        %me#unpress));

    async (fun () -> clicks cancel_button (fun ev _ -> %me#unpress))
  }};
  (container,
   the_input (*VVV Hack I return the input here -
               How to make this more elegant?
               May be turn it into an object? *))
}}


{client{
  let launch_selection_by_completion ?(cls_removebutton=cls_removebutton) ?(cls_tbox=cls_tbox)
      ?(cls_selected=cls_selected) ?(cls_completion_input=cls_completion_input)
      ~print ~remove ~contains ~get_string
      ~get_from_server ~build_licontent ~t_of_data ~t_of_string ~msg
      ~switch_to_restrictive ~selector () =

  let print_removable obj selected selected_list =
    let del_button = D.button ~a:[a_class [cls_removebutton]]
      ~button_type:`Button [Icons.remove] in
    let son = D.span ~a:[a_class [cls_tbox]]
      [print obj ; del_button] in

    Lwt_js_events.async (fun () ->
      Lwt_js_events.clicks (To_dom.of_button del_button)
        (fun _ _ ->
          Manip.removeChild selected son;
          selected_list := remove obj !selected_list;
          Lwt.return ()));
    son
  in


  (***************** FUNCTIONS REQUIRED BY COMPLETION WIDGET  ****************)
  let build_data = function
    | Ew_completion.Data d -> t_of_data d
    | Ew_completion.Raw s -> t_of_string s
  in



  let continue i selected selected_list ?t () =
    match t with
      | None -> ()
      | Some o ->
        begin
          let i = To_dom.of_input i in
          let elt = print_removable o selected selected_list in
          let open Lwt_js_events in

              Lwt_js_events.async (fun () ->
                clicks (To_dom.of_span selector) (fun _ _ ->
                  i##focus(); Lwt.return ()));

              Lwt_js_events.async (fun () ->
                if not (contains !selected_list o)
                then selected_list := o::!selected_list ;
                Manip.appendChild selected elt;
                i##value <- Js.string "";
                Lwt.return ())
        end
  in


  let i = D.raw_input ~input_type:`Text
    ~a:[a_class [cls_completion_input]; a_placeholder msg] () in
  let selected = D.span ~a:[a_class [cls_selected]] [] in
  let selected_list = ref [] in

  Manip.appendChild selector selected;
  Manip.appendChild selector i;

  Lwt_js_events.async (fun () ->
    let continue = continue i selected selected_list in
    let _ = new Ew_completion.completion_on
      ~input:(To_dom.of_input i)
      ~switch_to_restrictive:switch_to_restrictive
      ~handle_unrestricted_wrong_entry:(fun _ _ -> ())
      ~get_from_server:get_from_server
      ~get_string:get_string
      ~build_licontent:(build_licontent get_string)
      ~build_data:build_data
      ~continue:continue
    in
    Lwt.return ());

  selected, i, selected_list
}}
