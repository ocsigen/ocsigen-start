(* Copyright Vincent Balat *)

{shared{
open Eliom_content.Html5
open Eliom_content.Html5.F

type radio_set = (unit -> unit Lwt.t) ref

}}


{client{
let new_radio_set () : radio_set = ref Lwt.return

(** Something that behave like a button, with press, unpress and switch action.
    If [pressed] is true (default false) the button is pressed by default.
    If [button] is present (with some DOM element), this element will be used
    as a button: click on it will trigger actions open or close alternatively.
    If [set] is present, the button will act like a radio button: only one
    with the same set can be opened at the same time.
    Call function [new_radio_set] to create a new set.
    If [button_closeable] is false, then the button will open but not close.
    If [method_closeable] is false, then the unpress method will have no effect.
    If both are false, the only way to unpress is
    to press another one belonging to the same set.

    Redefine [press_action] and [unpress_action] for your needs.

    Redefine [pre_press] [post_press] [pre_unpress] or [post_unpress]
    if you want something to happen just before or after pressing/unpressing.
*)
class buh ?(pressed = false) ?button ?set
  ?(method_closeable=true) ?(button_closeable=true) () =
  let set_close_last, close_last = match set with
    | None -> (fun _ -> ()), Lwt.return
    | Some r -> (fun f -> r := f), (fun () -> !r ())
  in
object (me)
  val mutable press_state = pressed
  method pre_press = Lwt.return ()
  method post_press = Lwt.return ()
  method pre_unpress = Lwt.return ()
  method post_unpress = Lwt.return ()
  method press_action = Lwt.return ()
  method unpress_action = Lwt.return ()
  method pressed = press_state
  method press =
    lwt () = close_last () in
    set_close_last (fun () -> me#really_unpress);
    press_state <- true;
    Eba_misc.apply_option (Eba_misc.add_class "ew_pressed") button;
    lwt () = me#pre_press in
    lwt () = me#press_action in
    me#post_press
  method private really_unpress =
    set_close_last Lwt.return;
    press_state <- false;
    Eba_misc.apply_option (Eba_misc.remove_class "ew_pressed") button;
    lwt () = me#pre_unpress in
    lwt () = me#unpress_action in
    me#post_unpress
  method unpress = if method_closeable then me#really_unpress else Lwt.return ()
  method switch = if press_state then me#unpress else me#press
  method private button_switch = if press_state
    then (if button_closeable then me#really_unpress else Lwt.return ())
    else me#press
  initializer
    if pressed
    then begin
      set_close_last (fun () -> me#really_unpress);
      Eba_misc.apply_option (Eba_misc.add_class "ew_pressed") button
    end;
    match button with
      | None -> ()
      | Some b -> Lwt_js_events.async
        (fun () -> Lwt_js_events.clicks b (fun _ _ -> me#button_switch))
end

(** Alert displays an alert box when a button is pressed.
    [get_node] returns the list of elements to be displayed and

    Redefine [get_node] for your needs.

    If you want the alert to be opened at start,
    give an element as [pressed] parameter.
    It must have at the right parent in the page (body by default).

    After getting the node,
    the object is inserted as JS field [o] of the DOM element of
    the alert box.
*)
class [ 'a ] alert ?pressed ?button ?set ?method_closeable ?button_closeable
  ?(parent_node = (Dom_html.document##body :> Dom_html.element Js.t))
  ?(class_=[]) () =
object (me)
  inherit buh ~pressed:(pressed <> None) ?button ?set
    ?method_closeable ?button_closeable ()
  val node = ref None
  val mutable parent_node = parent_node
  method get_node : 'a Eliom_content.Html5.D.elt list Lwt.t
    = Lwt.return []
  method set_parent_node p = parent_node <- p
  method press_action =
    lwt n = me#get_node in
    let n = D.div ~a:[a_class ("ew_alert"::class_)] n in
    (Js.Unsafe.coerce (To_dom.of_div n))##o <- me;
    let n = To_dom.of_div n in
    node := Some n;
    Dom.appendChild parent_node n;
    Lwt.return ()
  method unpress_action =
    (match !node with
      | None -> ()
      | Some n -> try Dom.removeChild parent_node n with _ -> ());
    Lwt.return ()
  initializer
    match pressed with
      | None -> ()
      | Some elt ->
        (Js.Unsafe.coerce elt)##o <- me;
        Js.Opt.iter (elt##parentNode)
          (fun p -> Js.Opt.iter (Dom_html.CoerceTo.element p)
            (fun p -> parent_node <- p));
        node := pressed
end

(** show_hide shows or hides a box when pressed/unpressed.
    Set style property "display: none" for unpressed elements if
    you do not want them to appear shortly when the page is displayed.
*)
class [ 'a ] show_hide ?(pressed = false) ?button ?set
  ?method_closeable ?button_closeable elt =
object (me)
  inherit buh ~pressed ?button ?set ?method_closeable ?button_closeable ()
  method press_action =
    elt##style##display <- Js.string "block"; (*VVV No: restore default value *)
    Lwt.return ()
  method unpress_action =
    elt##style##display <- Js.string "none";
    Lwt.return ()
  initializer
    if not pressed
    then elt##style##display <- Js.string "none" (*VVV will blink ... *)
end

}}
