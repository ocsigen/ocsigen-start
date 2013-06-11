(* Copyright Séverine Maingaud *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

(*** Basic functions on string and string list ***)
{shared{
  let cls_completion = "el_completion"
  let cls_completion_highlight = "el_completion_highlight"
}}


{server{
  module M = Netstring_pcre

  let search rex w =
    try Some (M.search_forward rex w 0) with
      | Not_found -> None

  let regex_case_insensitive = M.regexp_case_fold
}}

{client{
  module M = Regexp

  let search rex w = M.search rex w 0

  let regex_case_insensitive w =
    M.regexp_with_flag w  "i"
}}


{shared{
  type 'a data = Data of 'a | Raw of string

  let build_pattern w =
    let w = M.quote w in
    regex_case_insensitive  (("^" ^ w) ^ "|\\s" ^ w)


  let search_case_insensitive w0 w1 =
    if w0 = "" || w0 = w1
    then None
    else
      let pattern = (build_pattern w0) in
      match search pattern w1 with
        | None -> None
        | Some (i,r) -> if i = 0 then Some (i,r) else Some (i+1, r)
}}


{server{
  (* arguments are utf8 caml string *)
  let search_case_accents_i w0 w1 =
    let w0 = Ew_accents.without w0 in
    let w1 = Ew_accents.without w1 in
    search_case_insensitive w0 w1
}}

{client{
  let search_case_accents_i w0 w1 =
    let w0 = Js.to_string (Ew_accents.removeDiacritics w0) in
    let w1 = Js.to_string (Ew_accents.removeDiacritics w1) in
    search_case_insensitive w0 w1 (*both arg are caml utf8 string *)
}}

{shared{
  let searchopt_to_bool w0 w1 =
    match search_case_accents_i w0 w1 with
      | None -> false
      | Some _ -> true
}}

{server{
  (* w1 is a completion of w0. ex: is_completed_by "e" "eddy" = yes *)
  (* arguments are utf8 caml string *)
  let is_completed_by w0 w1 =
    if w0 = "" || w1 = "" then false else searchopt_to_bool w0 w1
}}


{client{
  (* w1 is a completion of w0. ex: is_completed_by "e" "eddy" = yes *)
  (* both arg are utf16 JS string *)
  let is_completed_by w0 w1 =
    if w0 = (Js.string "") || w1 = ""
    then false else searchopt_to_bool w0 (Js.string w1)


  (* search in sp words with prefix ival and returns the list of suffixes *)
  (* first argument is a utf16 JS string *)
  let filter_js16 ival sp get_string =
    List.filter (fun a -> is_completed_by ival (get_string a)) sp
}}


{client{
class ['a] completion_on
  ~input:i
  ?(switch_to_restrictive=(fun _ -> true))
  ?(handle_unrestricted_wrong_entry=(fun _ _ -> ())) (*SSS TODO*)
  ~get_from_server
  ~get_string
  ~build_licontent
  ~build_data
  ~(continue: ?t:'a -> unit -> unit)
  =
  object (me)

    val mutable restrictive = true (* choice limited to the completion list? *)
    method set_restrictive b = restrictive <- b
    method prefix = Js.to_string i##value

    initializer

    let _ = Ol_misc.add_class cls_completion i in

    (* pointers to make it possible to: *)
    let old_child = ref (To_dom.of_ul (ul [])) in (*display fresh choices*)
    let selected_word = ref (-1) in (*write the word selected by the user*)
    let choices = ref [] in (*restrict search*)
    let lol = ref [] in (*selection of a word by the user*)
    let on = ref false in (*know if choices are shown*)
    let old_val = ref (Js.string "") in (*record the text entered by the user*)


     (* the container of all possible choices *)
    let container = D.div ~a:[a_class [cls_completion]] [] in
    let container = To_dom.of_div container in


    (*** functions to highlight a li-line depending on
       events: arrow up et arrow down and update input##value ***)
    let incr_sw () =
      let n = List.length !choices in
      let m = if restrictive then (n-1) else n in
      if m > 0
      then selected_word := ((!selected_word + 1) mod (m+1))
    in

    let decr_sw () =
      let n = List.length !choices in
      let m = if restrictive then (n-1) else n in
      if m > 0
      then if !selected_word = 0 then selected_word := m
        else selected_word := (!selected_word - 1)
    in


    let initialize_selector () =
      selected_word := if restrictive then 0 else (-1)
    in

    (* n is supposed to range from 0 to lol-length
      --- (lol-length-1 if restrictive = true *)
    (* Note: highlight_line n returns the string of line n *)
    let highlight_off () =
      let (ul_ : Dom_html.uListElement Js.t) = !old_child in
      let cls = Js.string ("."^cls_completion_highlight) in
      let old_line = ul_##querySelector(cls) in
      let some =
        fun line -> Ol_misc.remove_class cls_completion_highlight line
      in
      Js.Opt.iter old_line some
    in


    (* highlight_line is supposed to be called only when !lol is not empty *)
    let highlight_line n =
      match !lol with
        | [] -> "" (* not supposed to happens *)
        | l ->
          begin
            highlight_off (); (* supposed to be useless, but in case... *)
            if n < (List.length l)
            then let new_line = To_dom.of_li (List.nth l (max n 0)) in
                 Ol_misc.add_class cls_completion_highlight new_line;
                 get_string (List.nth !choices (max n 0))
            else (Js.to_string i##value)
          end
    in


    let set_input_value s =
      i##value <- (Js.string s)
    in


    let highlight_and_set_input_value n =
      if n = (List.length !lol)
      then
        (if not restrictive
         then (highlight_off () ; i##value <- !old_val)
         (* else: not supposed to happens *))
      else set_input_value (highlight_line n) (*highlight returns a string*)
    in


    (*** functions to display or not the box containing the choices list ***)
    let display_on () =
      let width = (Js.string ((string_of_int (i##clientWidth))^"px")) in
      let vdecal = (i##clientHeight) + (Dom_html.document##body##scrollTop) in
      let hdecal = (Dom_html.document##body##scrollLeft) in
      let rectopt = i##getClientRects()##item(0) in
      let (containerTop, containerLeft) =
        Js.Opt.case rectopt
          (fun rect -> (Js.string "0px", Js.string "0px"))
          (fun rect ->
            let to_css decal x =
              let entier = (int_of_float (Js.to_float x)) + decal in
              (Js.string ((string_of_int entier) ^ "px"))
            in
            (to_css vdecal rect##top, to_css hdecal rect##left))
      in
      container##style##width <- width;
      container##style##top <- containerTop;
      container##style##left <- containerLeft;
      if !on then ()
      else
        (Dom.appendChild container !old_child;
         Dom.appendChild Dom_html.document##body container;
         on := true)
    in

    let display () =
      let ul_ = D.ul ~a:[a_class [cls_completion]] !lol in
      let new_child = To_dom.of_ul ul_ in
      Dom.replaceChild container new_child !old_child;
      if restrictive then ignore (highlight_line 0);
      old_child := new_child
    in


    let display_off () =
      if !on then
        (Dom.removeChild Dom_html.document##body container;
         on := false)
    in


    (*** Build the ul-content from the choices list ***)
    (* the list l is supposed to contain only completions of i##value *)
    (* a completion of m is supposed to be longer than m*)
    let list_of_li s s_wa =
      let rec aux l acc = match l with
        | [] -> acc
        | data::ll ->
          begin
            match search_case_accents_i s (Js.string (get_string data)) with
              | None ->  aux ll acc
              | Some (i,_) ->
                let select _ =
                  display_off ();
                  continue ~t:(build_data (Data data)) ();
                  true
                in
                let li_ = D.li
                  ~a:[a_class [cls_completion]; a_onclick select]
                  (build_licontent s_wa data i)
              in
              aux ll (acc@[li_])
          end
      in
      aux !choices []
    in


    let go () =
      if i##value = (Js.string "") then continue ()
      else
        if restrictive
        then (match !choices with
          | [] -> ()
          | l -> let data = List.nth l (max 0 !selected_word) in
                 i##value <- (Js.string (get_string data));
                 let data = build_data (Data data) in
                 continue ~t:data ())
        else
          let raw_data = build_data (Raw (Js.to_string i##value)) in
          continue ~t:raw_data ()
    in



    Lwt.async (fun () ->
      Lwt_js_events.inputs i
        (fun ev _ ->
          display_off ();
          if i##value = Js.string ""
          then (choices := [];
                lol := [];
                old_val := Js.string "";
                initialize_selector ();
                Lwt.return ())
          else
            begin
              let i_js16 = i##value in
              let i_caml8 = Js.to_string i_js16 in
              lwt () =
                if is_completed_by !old_val i_caml8
                then (choices := (filter_js16 i_js16 !choices get_string) ;
                      Lwt.return ())
                else (lwt l = get_from_server i_caml8 in
                      choices := l;
                      old_val := Js.string "";
                      Lwt.return ())
              in
              restrictive <- (switch_to_restrictive i_caml8);
              let i_wa = Ew_accents.removeDiacritics i_js16 in
              let i_wa_caml8 = Js.to_string i_wa in
              (match !choices with
                | [] -> display_off ()
                | l ->
                  begin
                    lol := (list_of_li i_js16 i_wa_caml8);
                    old_val := i_js16;
                    initialize_selector ();
                    match !lol with
                      | [] -> display_off ()
                      | _ ->  display_on (); display ()
                  end);
              Lwt.return ();
            end
        )
    );


    Lwt.async (fun () ->
      Lwt_js_events.keydowns i
        (fun ev _ ->
          (match ev##keyCode with
            | 13  ->  (*enter*)
              (if not (i##value = Js.string "")
               then Lwt_js_events.preventDefault ev;
               display_off (); go ())

            | 9 ->   (*tab*)
              (if not (i##value = Js.string "")
               then Lwt_js_events.preventDefault ev;
               display_off (); go ())

            | 27  ->  (*escape*)
              (Lwt_js_events.preventDefault ev;
               set_input_value "" ;
               display_off ())

            (* selecting a word in the list with arrows *)
            | 38 ->  (*arrow up*)
              if i##value <> Js.string ""
              then
                (decr_sw (); highlight_and_set_input_value !selected_word);

            | 40 -> (*arrow down*)
              if i##value <> Js.string ""
              then
                (incr_sw (); highlight_and_set_input_value !selected_word);

            | _ -> ());

          Lwt.return ();
        )
    );


    Lwt.async (fun () ->
      (* HACK HACK HACK CA DEFONCE MES BOUTTONS ! *)
      Lwt_js_events.clicks Dom_html.document
        (fun ev _ ->
          (*Lwt_js_events.preventDefault ev;*)
          Dom_html.stopPropagation ev;
          set_input_value "";
          display_off ();
          Lwt.return ())
    )
  end
}}
