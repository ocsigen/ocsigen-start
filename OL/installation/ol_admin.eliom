{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

exception Not_admin

let open_service_handler () () =
  Ol_misc.log "open";
  Ol_site.set_state Ol_site.Open

let close_service_handler () () =
  Ol_misc.log "close";
  Ol_site.set_state Ol_site.Close

let confirm_box service value content =
    post_form ~service
      (fun () ->
         [fieldset
            [
              content;
              string_input
                ~input_type:`Submit
                ~value
                ()
            ]
         ]) ()

{shared{
  type buh_t =
      < press : unit Lwt.t;
      unpress : unit Lwt.t;
      pre_press : unit Lwt.t;
      pre_unpress : unit Lwt.t;
      post_press : unit Lwt.t;
      post_unpress : unit Lwt.t;
      press_action: unit Lwt.t;
      unpress_action: unit Lwt.t;
      switch: unit Lwt.t;
      pressed: bool;
      >
}}

let close_state_desc =
  div [
    p [pcdata "In CLOSE mode, a user can:"];
    ul [
      li [pcdata "- pre-register an account"];
      li [pcdata "- log in"]
    ]
  ]

(* CHARLY: use html tags instead of caml strings for better presentation ? *)
let open_state_desc =
  div [
    p [pcdata "In OPEN mode, a user can:"];
    ul [
      li [pcdata "- open/create an account"];
      li [pcdata "- retrieve his password"];
      li [pcdata "- log in"]
    ]
  ]

let admin_page_content user set_as_rpc =
  let open Ol_base_widgets in
  lwt state = Ol_site.get_state () in
  let enable_if b =
    if b then "ol_current_state"
    else ""
  in
  let set = {Ew_buh.radio_set{ Ew_buh.new_radio_set () }} in
  let button1, form1 =
    D.h2 ~a:[a_class [enable_if (state = Ol_site.Close)]] [pcdata "CLOSE"],
    confirm_box Ol_services.open_service
      "switch to open mode"
      open_state_desc
  in
  let close_state_div =
    D.div ~a:[
      a_id "ol_close_state";
      a_class [enable_if (state = Ol_site.Close)]] [
        form1
      ]
  in
  let radio1 = {buh_t{
    new Ew_buh.show_hide
      ~pressed:(%state = Ol_site.Close)
      ~set:%set ~button:(To_dom.of_h2 %button1)
      ~button_closeable:false
      (To_dom.of_div %close_state_div)
  }}
  in
  let button2, form2 =
    D.h2 ~a:[a_class [enable_if (state = Ol_site.Open)]] [pcdata "OPEN"],
    confirm_box Ol_services.close_service
       "switch to close mode"
       close_state_desc
  in
  let open_state_div =
    D.div ~a:[
      a_id "ol_open_state";
      a_class [enable_if (state = Ol_site.Open)]] [
        form2
      ]
  in
  let radio2 = {buh_t{
    new Ew_buh.show_hide
      ~pressed:(%state = Ol_site.Open)
      ~set:%set ~button:(To_dom.of_h2 %button2)
      ~button_closeable:false
      (To_dom.of_div %open_state_div)
  }}
  in
  ignore {unit{
    ignore ((%radio2)#press)
  }};
  let users_box = D.div [] in
  let widget = D.div [] in
  (* I create a dummy button because the completion widget need it,
   * but it seems to be not used at all by the widget so.. *)
  let dummy_data = D.h2 [pcdata "dummy"] in
  let dummy_button = {buh_t{
    new Ew_buh.buh
      ~button:(To_dom.of_h2 %dummy_data)
      ()
  }} in
  let _ = {unit{
    let module MBW =
      Ol_users_base_widgets.MakeBaseWidgets(Ol_admin_completion) in
    let module M = Ol_users_selector_widget.MakeSelectionWidget(MBW) in
    let handler l =
      let f e =
        let member_handler u =
          let b1 = D.p ~a:[a_class ["ol_admin_button"]] [pcdata "admin"] in
          let b2 = D.p ~a:[a_class ["ol_admin_button"]] [pcdata "beta"] in
          let b3 = D.p ~a:[a_class ["ol_admin_button"]] [pcdata "user"] in
          (*
          let enable_with_rights r =
            Ol_misc.remove_class "ol_enabled" (To_dom.of_p b1);
            Ol_misc.remove_class "ol_enabled" (To_dom.of_p b2);
            Ol_misc.remove_class "ol_enabled" (To_dom.of_p b3);
            match r with
              | Ol_common0.Admin ->
                  Ol_misc.add_class "ol_enabled" (To_dom.of_p b1)
              | Ol_common0.Beta  ->
                  Ol_misc.add_class "ol_enabled" (To_dom.of_p b2)
              | Ol_common0.User  ->
                  Ol_misc.add_class "ol_enabled" (To_dom.of_p b3)
          in
          *)
          let open Lwt_js_events in
          let uid_member = (MBW.id_of_member u) in
          (*
          let r = (Ol_common0.rights_to_type (MBW.rights_of_member u)) in
          *)
          let to_dom e = To_dom.of_p e in
            (*
            Lwt.async (fun () ->
                         (clicks (to_dom b1)
                            (fun _ _ ->
                               enable_with_rights Ol_common0.Admin;
                               %set_as_rpc (uid_member, Ol_common0.Admin))));
            Lwt.async (fun () ->
                         (clicks (to_dom b2)
                            (fun _ _ ->
                               enable_with_rights Ol_common0.Beta;
                               %set_as_rpc (uid_member, Ol_common0.Beta))));
            Lwt.async (fun () ->
                         (clicks (to_dom b3)
                            (fun _ _ ->
                               enable_with_rights Ol_common0.User;
                               %set_as_rpc (uid_member, Ol_common0.User))));
            enable_with_rights r;
            *)
            D.div ~a:[a_class ["ol_admin_user_box"]] [
              p [pcdata (MBW.name_of_member u)];
              b1; b2; b3;
            ]
        in
          match e with
            | MBW.Member u ->
                Eliom_content.Html5.Manip.appendChild
                  (%users_box)
                  (member_handler u);
            | MBW.Invited m ->
                (* This should never happen. We don't want that an admin
                 * try to modify user right on an email which is not
                 * registered *)
                Eliom_lib.alert "This account does not exist: %s" m
      in
        List.iter f l;
        Lwt.return ()
    in
    let select, input = M.member_selector
                          handler
                          "select user"
                          %dummy_button
    in
      Eliom_content.Html5.Manip.appendChild %widget select;
      Eliom_content.Html5.Manip.appendChild %widget input;
      ()
  }} in
    Lwt.return
      [
        div ~a:[a_id "ol_admin_welcome"] [
          h1 [pcdata ("welcome " ^ (Ol_common0.name_of_user user))];
        ];
        button1; button2;
        close_state_div; open_state_div;
        widget;
        users_box
      ]

let admin_service_handler
      page_container
      set_as_rpc
      uid () () =
  lwt user = Ol_db.get_user uid in
  if not (false) (* INSERT: is_admin ? *)
   (* should be handle with an exception caught in the Connection_Wrapper ?
    * or just return some html5 stuffs to tell that the user can't reach this
    * page ? (404 ?) *)
  then
    let content =
      div ~a:[a_class ["ol_error"]] [
        h1 [pcdata "You're not allowed to access to this page."];
        a ~a:[a_class ["ol_link_error"]]
          ~service:Ol_services.main_service
          [pcdata "back"]
          ()
      ]
    in
    Lwt.return
      (page_container [content])
  else
    lwt content = admin_page_content user set_as_rpc in
    Lwt.return
      (page_container content)
