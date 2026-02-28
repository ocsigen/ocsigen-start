(* Demo page for Ot_form widgets *)

open%shared Eliom_content.Html
open%shared Eliom_content.Html.F
open%client Js_of_ocaml
open%client Js_of_ocaml_lwt

let%shared section title content =
  div
    ~a:[a_class ["demo-forms-section"]]
    (h3 [txt title] :: content)

let%shared output_line label signal =
  p
    ~a:[a_class ["demo-forms-output"]]
    [ strong [txt (label ^ ": ")]
    ; R.txt (Eliom_shared.React.S.map [%shared fun v -> v] signal) ]

let%shared page () =
  (* -- standard form -- *)
  let name_inp =
    D.Raw.input
      ~a:[a_input_type `Text; a_placeholder [%i18n Demo.S.form_standard_name]]
      ()
  in
  let email_inp =
    D.Raw.input
      ~a:[a_input_type `Email; a_placeholder [%i18n Demo.S.form_standard_email]]
      ()
  in
  let phone_inp =
    D.Raw.input
      ~a:[a_input_type `Tel; a_placeholder [%i18n Demo.S.form_standard_phone]]
      ()
  in
  let age_inp =
    D.Raw.input
      ~a:[ a_input_type `Number
         ; a_input_min (`Number 0)
         ; a_input_max (`Number 150)
         ; a_placeholder [%i18n Demo.S.form_standard_age] ]
      ()
  in
  let date_inp = D.Raw.input ~a:[a_input_type `Date] () in
  let time_inp = D.Raw.input ~a:[a_input_type `Time] () in
  let pwd_inp =
    D.Raw.input
      ~a:[ a_input_type `Password
         ; a_placeholder [%i18n Demo.S.form_standard_password] ]
      ()
  in
  let pwd_container = Ot_form.password_toggle pwd_inp in
  let msg_inp =
    D.Raw.textarea
      ~a:[a_placeholder [%i18n Demo.S.form_standard_message]]
      (txt "")
  in
  let country_sel =
    D.Raw.select
      [ D.Raw.option ~a:[a_value "fr"] (txt "France")
      ; D.Raw.option ~a:[a_value "de"] (txt "Germany")
      ; D.Raw.option ~a:[a_value "it"] (txt "Italy")
      ; D.Raw.option ~a:[a_value "es"] (txt "Spain") ]
  in
  let radio_m =
    D.Raw.input
      ~a:[a_input_type `Radio; a_name "std-gender"; a_value "M"]
      ()
  in
  let radio_f =
    D.Raw.input
      ~a:[a_input_type `Radio; a_name "std-gender"; a_value "F"]
      ()
  in
  let radio_o =
    D.Raw.input
      ~a:[a_input_type `Radio; a_name "std-gender"; a_value "O"]
      ()
  in
  let terms_cb = D.Raw.input ~a:[a_input_type `Checkbox] () in
  let satisfaction_inp =
    D.Raw.input
      ~a:[ a_input_type `Range
         ; a_input_min (`Number 0)
         ; a_input_max (`Number 100)
         ; a_value "50" ]
      ()
  in
  let color_inp =
    D.Raw.input ~a:[a_input_type `Color; a_value "#2563eb"] ()
  in
  let submit_btn =
    D.button
      ~a:[a_button_type `Button; a_class ["button"]]
      [txt [%i18n Demo.S.form_standard_submit]]
  in
  let result_div = D.div [] in
  let name_l = [%i18n Demo.S.form_standard_name] in
  let email_l = [%i18n Demo.S.form_standard_email] in
  let phone_l = [%i18n Demo.S.form_standard_phone] in
  let age_l = [%i18n Demo.S.form_standard_age] in
  let date_l = [%i18n Demo.S.form_standard_birthdate] in
  let time_l = [%i18n Demo.S.form_standard_time] in
  let pwd_l = [%i18n Demo.S.form_standard_password] in
  let msg_l = [%i18n Demo.S.form_standard_message] in
  let country_l = [%i18n Demo.S.form_standard_country] in
  let gender_l = [%i18n Demo.S.form_standard_gender] in
  let terms_l = [%i18n Demo.S.form_standard_terms] in
  let satisfaction_l = [%i18n Demo.S.form_standard_satisfaction] in
  let color_l = [%i18n Demo.S.form_standard_color] in
  let (_ : unit Eliom_client_value.t) =
    [%client
      let btn_el = To_dom.of_element ~%submit_btn in
      let result_el = To_dom.of_element ~%result_div in
      let get_input v = Js.to_string (To_dom.of_input v)##.value in
      let get_checked v = Js.to_bool (To_dom.of_input v)##.checked in
      Lwt.async (fun () ->
        Lwt_js_events.clicks btn_el (fun _ _ ->
          let lines =
            [ Printf.sprintf "%s: %s" ~%name_l (get_input ~%name_inp)
            ; Printf.sprintf "%s: %s" ~%email_l (get_input ~%email_inp)
            ; Printf.sprintf "%s: %s" ~%phone_l (get_input ~%phone_inp)
            ; Printf.sprintf "%s: %s" ~%age_l (get_input ~%age_inp)
            ; Printf.sprintf "%s: %s" ~%date_l (get_input ~%date_inp)
            ; Printf.sprintf "%s: %s" ~%time_l (get_input ~%time_inp)
            ; Printf.sprintf "%s: %s" ~%pwd_l
                (String.make (String.length (get_input ~%pwd_inp)) '*')
            ; Printf.sprintf "%s: %s" ~%msg_l
                (Js.to_string (To_dom.of_textarea ~%msg_inp)##.value)
            ; Printf.sprintf "%s: %s" ~%country_l
                (Js.to_string (To_dom.of_select ~%country_sel)##.value)
            ; Printf.sprintf "%s: %s" ~%gender_l
                (let m = get_checked ~%radio_m in
                 let f = get_checked ~%radio_f in
                 if m then "M" else if f then "F" else "O")
            ; Printf.sprintf "%s: %s" ~%terms_l
                (if get_checked ~%terms_cb then "yes" else "no")
            ; Printf.sprintf "%s: %s" ~%satisfaction_l
                (get_input ~%satisfaction_inp)
            ; Printf.sprintf "%s: %s" ~%color_l (get_input ~%color_inp) ]
          in
          result_el##.innerHTML :=
            Js.string (String.concat "<br>" lines);
          Lwt.return_unit))]
  in
  let field lbl content =
    div ~a:[a_class ["demo-forms-field"]]
      [label [strong [txt lbl]]; content]
  in
  let std_section =
    section [%i18n Demo.S.form_standard_title]
      [ p [txt [%i18n Demo.S.form_standard_desc]]
      ; field [%i18n Demo.S.form_standard_name] name_inp
      ; field [%i18n Demo.S.form_standard_email] email_inp
      ; field [%i18n Demo.S.form_standard_phone] phone_inp
      ; field [%i18n Demo.S.form_standard_age] age_inp
      ; field [%i18n Demo.S.form_standard_birthdate] date_inp
      ; field [%i18n Demo.S.form_standard_time] time_inp
      ; field [%i18n Demo.S.form_standard_password] pwd_container
      ; field [%i18n Demo.S.form_standard_message] msg_inp
      ; field [%i18n Demo.S.form_standard_country] country_sel
      ; field [%i18n Demo.S.form_standard_gender]
          (div
             [ label [radio_m; txt (" " ^ [%i18n Demo.S.form_standard_gender_m])]
             ; txt " "
             ; label [radio_f; txt (" " ^ [%i18n Demo.S.form_standard_gender_f])]
             ; txt " "
             ; label [radio_o; txt (" " ^ [%i18n Demo.S.form_standard_gender_o])]
             ])
      ; field [%i18n Demo.S.form_standard_terms]
          (label [terms_cb; txt (" " ^ [%i18n Demo.S.form_standard_terms])])
      ; field [%i18n Demo.S.form_standard_satisfaction] satisfaction_inp
      ; field [%i18n Demo.S.form_standard_color] color_inp
      ; div [submit_btn]
      ; div
          ~a:[a_class ["demo-forms-output"]]
          [ strong [txt ([%i18n Demo.S.form_standard_result] ^ ":")]
          ; result_div ] ]
  in
  (* -- reactive_input -- *)
  let ri_input, (ri_signal, _ri_set) = Ot_form.reactive_input ~value:"hello" () in
  let ri_section =
    section [%i18n Demo.S.form_reactive_input_title]
      [ p [txt [%i18n Demo.S.form_reactive_input_desc]]
      ; ri_input
      ; output_line [%i18n Demo.S.form_label_value] ri_signal ]
  in
  (* -- reactive_textarea -- *)
  let rt_elt, (rt_signal, _rt_set) =
    Ot_form.reactive_textarea ~resize:true ~a_rows:3
      ~a_placeholder:[%i18n Demo.S.form_placeholder_type_here] ()
  in
  let rt_section =
    section [%i18n Demo.S.form_reactive_textarea_title]
      [ p [txt [%i18n Demo.S.form_reactive_textarea_desc]]
      ; rt_elt
      ; output_line [%i18n Demo.S.form_label_value] rt_signal ]
  in
  (* -- debounced_input -- *)
  let db_input, (db_raw, db_debounced, _db_set) =
    Ot_form.debounced_input ~delay:0.5 ~value:"" ()
  in
  let db_section =
    section [%i18n Demo.S.form_debounced_title]
      [ p [txt [%i18n Demo.S.form_debounced_desc]]
      ; db_input
      ; output_line [%i18n Demo.S.form_label_raw] db_raw
      ; output_line [%i18n Demo.S.form_label_debounced] db_debounced ]
  in
  (* -- password_input -- *)
  let pw_container, _pw_input, (pw_visible_s, _pw_set_visible) =
    Ot_form.password_input ~placeholder:[%i18n Demo.S.form_placeholder_password] ()
  in
  let true_s = [%i18n Demo.S.form_true] in
  let false_s = [%i18n Demo.S.form_false] in
  let pw_section =
    section [%i18n Demo.S.form_password_title]
      [ p [txt [%i18n Demo.S.form_password_desc]]
      ; pw_container
      ; p
          ~a:[a_class ["demo-forms-output"]]
          [ strong [txt ([%i18n Demo.S.form_label_visible] ^ ": ")]
          ; R.txt
              (Eliom_shared.React.S.map
                 [%shared fun v -> if v then ~%true_s else ~%false_s]
                 pw_visible_s) ] ]
  in
  (* -- reactive_select -- *)
  let sel_elt, (sel_signal, _sel_set) =
    Ot_form.reactive_select
      ~options:
        [ "fr", "France"
        ; "de", "Germany"
        ; "it", "Italy"
        ; "es", "Spain" ]
      ~selected:"fr" ()
  in
  let sel_section =
    section [%i18n Demo.S.form_select_title]
      [ p [txt [%i18n Demo.S.form_select_desc]]
      ; sel_elt
      ; output_line [%i18n Demo.S.form_label_selected] sel_signal ]
  in
  (* -- reactive_toggle_button -- *)
  let toggle_btn, (toggle_s, _toggle_set) =
    Ot_form.reactive_toggle_button [txt [%i18n Demo.S.form_toggle_label]]
  in
  let on_s = [%i18n Demo.S.form_on] in
  let off_s = [%i18n Demo.S.form_off] in
  let toggle_section =
    section [%i18n Demo.S.form_toggle_title]
      [ p [txt [%i18n Demo.S.form_toggle_desc]]
      ; toggle_btn
      ; p
          ~a:[a_class ["demo-forms-output"]]
          [ strong [txt ([%i18n Demo.S.form_label_state] ^ ": ")]
          ; R.txt
              (Eliom_shared.React.S.map
                 [%shared fun v -> if v then ~%on_s else ~%off_s]
                 toggle_s) ] ]
  in
  (* -- checkbox -- *)
  let cb_label, _cb_input =
    Ot_form.checkbox ~style:`Box [txt [%i18n Demo.S.form_checkbox_box]]
  in
  let cb_label2, _cb_input2 =
    Ot_form.checkbox ~style:`Toggle [txt [%i18n Demo.S.form_checkbox_toggle]]
  in
  let cb_label3, _cb_input3 =
    Ot_form.checkbox ~style:`Bullet [txt [%i18n Demo.S.form_checkbox_bullet]]
  in
  let cb_section =
    section [%i18n Demo.S.form_checkbox_title]
      [ p [txt [%i18n Demo.S.form_checkbox_desc]]
      ; div [cb_label]
      ; div [cb_label2]
      ; div [cb_label3] ]
  in
  (* -- reactive_checkbox -- *)
  let rcb =
    Ot_form.reactive_checkbox ~style:`Box [txt [%i18n Demo.S.form_check_me]]
  in
  let rcb_section =
    section [%i18n Demo.S.form_reactive_checkbox_title]
      [ p [txt [%i18n Demo.S.form_reactive_checkbox_desc]]
      ; div [rcb#label]
      ; p
          ~a:[a_class ["demo-forms-output"]]
          [ strong [txt ([%i18n Demo.S.form_label_checked] ^ ": ")]
          ; R.txt
              (Eliom_shared.React.S.map
                 [%shared fun v -> if v then ~%true_s else ~%false_s]
                 rcb#value) ]
      ; p
          ~a:[a_class ["demo-forms-output"]]
          [ strong [txt ([%i18n Demo.S.form_label_manually_changed] ^ ": ")]
          ; R.txt
              (Eliom_shared.React.S.map
                 [%shared fun v -> if v then ~%true_s else ~%false_s]
                 rcb#manually_changed) ] ]
  in
  (* -- radio_buttons -- *)
  let radio_react = Eliom_shared.React.S.create (Some 0) in
  let radio_labels =
    Ot_form.radio_buttons
      ~selection_react:radio_react ~name:"demo-radio"
      [ [txt [%i18n Demo.S.form_radio_red]]
      ; [txt [%i18n Demo.S.form_radio_green]]
      ; [txt [%i18n Demo.S.form_radio_blue]] ]
  in
  let none_s = [%i18n Demo.S.form_none] in
  let radio_section =
    section [%i18n Demo.S.form_radio_title]
      [ p [txt [%i18n Demo.S.form_radio_desc]]
      ; div radio_labels
      ; p
          ~a:[a_class ["demo-forms-output"]]
          [ strong [txt ([%i18n Demo.S.form_label_selection] ^ ": ")]
          ; R.txt
              (Eliom_shared.React.S.map
                 [%shared
                   fun v ->
                     match v with
                     | None -> ~%none_s
                     | Some i -> string_of_int i]
                 (fst radio_react)) ] ]
  in
  (* -- int_input / optional_int_input -- *)
  let int_div, int_signal = Ot_form.int_input ~min:0 ~max:100 42 in
  let oint_div, oint_signal = Ot_form.optional_int_input ~min:0 ~max:50 (Some 10) in
  let invalid_s = [%i18n Demo.S.form_invalid] in
  let int_section =
    section [%i18n Demo.S.form_int_input_title]
      [ p [txt [%i18n Demo.S.form_int_input_desc]]
      ; div
          [ strong [txt "int_input: "]; int_div
          ; p
              ~a:[a_class ["demo-forms-output"]]
              [ strong [txt ([%i18n Demo.S.form_label_value] ^ ": ")]
              ; R.txt
                  (Eliom_shared.React.S.map
                     [%shared
                       fun v ->
                         match v with
                         | Ok n -> string_of_int n
                         | Error () -> ~%invalid_s]
                     int_signal) ] ]
      ; div
          [ strong [txt "optional_int_input: "]; oint_div
          ; p
              ~a:[a_class ["demo-forms-output"]]
              [ strong [txt ([%i18n Demo.S.form_label_value] ^ ": ")]
              ; R.txt
                  (Eliom_shared.React.S.map
                     [%shared
                       fun v ->
                         match v with
                         | Ok (Some n) -> string_of_int n
                         | Ok None -> ~%none_s
                         | Error () -> ~%invalid_s]
                     oint_signal) ] ] ]
  in
  (* -- reactive_date_input -- *)
  let date_input, (date_signal, _date_set) =
    Ot_form.reactive_date_input ~value:(2025, 6, 15) ()
  in
  let date_section =
    section [%i18n Demo.S.form_date_title]
      [ p [txt [%i18n Demo.S.form_date_desc]]
      ; date_input
      ; p
          ~a:[a_class ["demo-forms-output"]]
          [ strong [txt ([%i18n Demo.S.form_label_date] ^ ": ")]
          ; R.txt
              (Eliom_shared.React.S.map
                 [%shared
                   fun v ->
                     match v with
                     | Some (y, m, d) ->
                         Printf.sprintf "%04d-%02d-%02d" y m d
                     | None -> ~%none_s]
                 date_signal) ] ]
  in
  (* -- reactive_time_input -- *)
  let time_input, (time_signal, _time_set) =
    Ot_form.reactive_time_input ~value:(14, 30) ()
  in
  let time_section =
    section [%i18n Demo.S.form_time_title]
      [ p [txt [%i18n Demo.S.form_time_desc]]
      ; time_input
      ; p
          ~a:[a_class ["demo-forms-output"]]
          [ strong [txt ([%i18n Demo.S.form_label_time] ^ ": ")]
          ; R.txt
              (Eliom_shared.React.S.map
                 [%shared
                   fun v ->
                     match v with
                     | Some (h, m) -> Printf.sprintf "%02d:%02d" h m
                     | None -> ~%none_s]
                 time_signal) ] ]
  in
  (* -- disableable_button -- *)
  let dis_toggle_btn, (dis_s, _dis_set) =
    Ot_form.reactive_toggle_button ~init:false
      [txt [%i18n Demo.S.form_disable_below]]
  in
  let dis_button =
    Ot_form.disableable_button ~disabled:dis_s
      [txt [%i18n Demo.S.form_can_be_disabled]]
  in
  let dis_section =
    section [%i18n Demo.S.form_disableable_title]
      [ p [txt [%i18n Demo.S.form_disableable_desc]]
      ; div [dis_toggle_btn]
      ; div [dis_button] ]
  in
  (* -- prevent_double_submit -- *)
  let pds_button =
    Ot_form.prevent_double_submit
      ~f:[%client fun () -> Lwt_js.sleep 2.0]
      [txt [%i18n Demo.S.form_click_2s]]
  in
  let pds_section =
    section [%i18n Demo.S.form_prevent_double_title]
      [ p [txt [%i18n Demo.S.form_prevent_double_desc]]
      ; pds_button ]
  in
  (* -- input_validation_tools -- *)
  let even_error = [%i18n Demo.S.form_even_error] in
  let val_attrs, val_class, val_result =
    Ot_form.input_validation_tools
      ~init:""
      [%shared
        fun s ->
          if String.length s = 0 then Ok ""
          else
            match int_of_string_opt s with
            | Some n when n mod 2 = 0 -> Ok s
            | _ -> Error ~%even_error]
  in
  let val_input =
    D.Raw.input
      ~a:(a_input_type `Text
         :: a_placeholder [%i18n Demo.S.form_placeholder_even]
         :: val_class :: val_attrs)
      ()
  in
  let () = Ot_form.graceful_invalid_style val_input in
  let ok_prefix = [%i18n Demo.S.form_ok_prefix] in
  let error_prefix = [%i18n Demo.S.form_error_prefix] in
  let val_section =
    section [%i18n Demo.S.form_validation_title]
      [ p [txt [%i18n Demo.S.form_validation_desc]]
      ; val_input
      ; p
          ~a:[a_class ["demo-forms-output"]]
          [ strong [txt ([%i18n Demo.S.form_label_result] ^ ": ")]
          ; R.txt
              (Eliom_shared.React.S.map
                 [%shared
                   fun v ->
                     match v with
                     | Ok s -> ~%ok_prefix ^ s
                     | Error e -> ~%error_prefix ^ e]
                 val_result) ] ]
  in
  (* -- reactive_fieldset -- *)
  let fs_toggle, (fs_disabled_s, _fs_set) =
    Ot_form.reactive_toggle_button ~init:false
      [txt [%i18n Demo.S.form_disable_fieldset]]
  in
  let fs_input1, _ =
    Ot_form.reactive_input ~value:[%i18n Demo.S.form_field_1] ()
  in
  let fs_input2, _ =
    Ot_form.reactive_input ~value:[%i18n Demo.S.form_field_2] ()
  in
  let fs =
    Ot_form.reactive_fieldset ~disabled:fs_disabled_s
      [ div [strong [txt [%i18n Demo.S.form_fieldset_content]]]
      ; div [fs_input1]
      ; div [fs_input2]
      ; Ot_form.disableable_button
          ~disabled:(Eliom_shared.React.S.const false)
          [txt [%i18n Demo.S.form_button_inside]] ]
  in
  let fs_section =
    section [%i18n Demo.S.form_fieldset_title]
      [ p [txt [%i18n Demo.S.form_fieldset_desc]]
      ; div [fs_toggle]
      ; fs ]
  in
  (* -- lwt_bound_input_enter -- *)
  let enter_output = Eliom_shared.React.S.create "" in
  let enter_input =
    Ot_form.lwt_bound_input_enter
      ~a:[a_placeholder [%i18n Demo.S.form_placeholder_enter]]
      [%client
        fun v ->
          ~%(snd enter_output) ("[" ^ v ^ "]");
          Lwt.return_unit]
  in
  let enter_section =
    section [%i18n Demo.S.form_enter_title]
      [ p [txt [%i18n Demo.S.form_enter_desc]]
      ; enter_input
      ; output_line [%i18n Demo.S.form_label_submitted] (fst enter_output) ]
  in
  Lwt.return
    [ h1 [txt [%i18n Demo.S.form_widgets]]
    ; p [txt [%i18n Demo.S.form_intro]]
    ; std_section
    ; ri_section
    ; rt_section
    ; db_section
    ; pw_section
    ; sel_section
    ; toggle_section
    ; cb_section
    ; rcb_section
    ; radio_section
    ; int_section
    ; date_section
    ; time_section
    ; dis_section
    ; pds_section
    ; val_section
    ; fs_section
    ; enter_section ]

let%shared () =
  %%%MODULE_NAME%%%_base.App.register ~service:Demo_services.demo_forms
    ( %%%MODULE_NAME%%%_page.Opt.connected_page @@ fun myid_o () () ->
      let%lwt p = page () in
      %%%MODULE_NAME%%%_container.page ~a:[a_class ["os-page-demo-forms"]] myid_o p )
