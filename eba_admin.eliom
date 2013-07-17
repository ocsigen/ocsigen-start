{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

exception Not_admin

let open_service_handler () () =
  Eba_misc.log "open";
  Eba_site.set_state Eba_site.Open

let close_service_handler () () =
  Eba_misc.log "close";
  Eba_site.set_state Eba_site.Close

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
  type button_t =
      < press : unit Lwt.t;
      unpress : unit Lwt.t;
      on_pre_press : unit Lwt.t;
      on_pre_unpress : unit Lwt.t;
      on_post_press : unit Lwt.t;
      on_post_unpress : unit Lwt.t;
      on_press : unit Lwt.t;
      on_unpress : unit Lwt.t;
      switch : unit Lwt.t;
      pressed : bool;
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

{shared{
  module Ew = Eliom_widgets
}}

let admin_page_content user set_group_of_user_rpc get_groups_of_user_rpc =
  let open Eba_base_widgets in
  lwt state = Eba_site.get_state () in
  let enable_if b =
    if b then "ol_current_state"
    else ""
  in
  let set = {(Ew.Button.radio_set_t){ Ew.Button.new_radio_set () }} in
  let button1, form1 =
    D.h2 ~a:[a_class [enable_if (state = Eba_site.Close)]] [pcdata "CLOSE"],
    confirm_box Eba_services.open_service
      "switch to open mode"
      open_state_desc
  in
  let close_state_div =
    D.div ~a:[
      a_id "ol_close_state";
      a_class [enable_if (state = Eba_site.Close)]] [
        form1
      ]
  in
  let radio1 = {button_t{
    new Ew.Button.button_show_hide
      ~pressed:(%state = Eba_site.Close)
      ~set:%set ~button:%button1
      ~button_closeable:false
      %close_state_div
  }}
  in
  let button2, form2 =
    D.h2 ~a:[a_class [enable_if (state = Eba_site.Open)]] [pcdata "OPEN"],
    confirm_box Eba_services.close_service
       "switch to close mode"
       close_state_desc
  in
  let open_state_div =
    D.div ~a:[
      a_id "ol_open_state";
      a_class [enable_if (state = Eba_site.Open)]] [
        form2
      ]
  in
  let radio2 = {button_t{
    new Ew.Button.button_show_hide
      ~pressed:(%state = Eba_site.Open)
      ~set:%set ~button:%button2
      ~button_closeable:false
      %open_state_div
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
  let dummy_button = {button_t{
    new Ew.Button.button
      ~button:%dummy_data
      ()
  }} in
    (*
  let _ = {unit{
    let module MBW =
      Eba_users_base_widgets.MakeBaseWidgets(Eba_admin_completion) in
    let module M = Eba_users_selector_widget.MakeSelectionWidget(MBW) in
    let member_handler u =
      let open Lwt_js_events in
      let uid_member = (MBW.id_of_member u) in
      let radio_button_of (group, in_group) =
        let rb =
          D.raw_input
            ~a:(if in_group then [a_checked `Checked] else [])
            ~input_type:`Checkbox
            ~value:(Eba_groups.name_of group)
            ()
        in
        let () =
          Lwt.async
            (fun () ->
               let rb = (To_dom.of_input rb) in
               clicks rb
                 (fun _ _ ->
                    let checked = Js.to_bool rb##checked in
                      %set_group_of_user_rpc (uid_member, (checked, group))))
        in [
          rb;
          pcdata (Eba_groups.name_of group)
        ]
      in
      lwt groups = %get_groups_of_user_rpc uid_member in
      let rbs = List.concat (List.map (radio_button_of) groups) in
      let div_ct : [> Html5_types.body_content_fun] Eliom_content.Html5.F.elt list = [] in
      let div_ct =
        div_ct
        @ [p [pcdata (MBW.name_of_member u)]]
        @ rbs
      in
        Lwt.return
          (D.div ~a:[a_class ["ol_admin_user_box"]] div_ct)
    in
    let generate_groups_content_of_user e =
      (* CHARLY: this going to change with the new completion widget *)
      match e with
        | MBW.Member u ->
            lwt rb = member_handler u in
              Lwt.return
                (Eliom_content.Html5.Manip.appendChild
                   (%users_box)
                   (rb))
        | MBW.Invited m ->
            (* This should never happen. We don't want that an admin
             * try to modify user right on an email which is not
             * registered *)
            Lwt.return (Eliom_lib.alert "This account does not exist: %s" m)
    in
    let handler l =
      generate_groups_content_of_user (List.hd l)
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
     *)
  Lwt.return [
    div ~a:[a_id "ol_admin_welcome"] [
      h1 [pcdata ("welcome " ^ (Eba_common0.name_of_user user))];
    ];
    button1; button2;
    close_state_div; open_state_div;
    widget;
    users_box
  ]

let admin_service_handler
      page_container
      set_group_of_user_rpc
      get_groups_of_user_rpc
      uid () () =
  lwt user = Eba_db.get_user uid in
  lwt admin = Eba_groups.admin in
  lwt is_admin = (Eba_groups.in_group ~userid:uid ~group:admin) in
  if not is_admin
   (* should be handle with an exception caught in the Connection_Wrapper ?
    * or just return some html5 stuffs to tell that the user can't reach this
    * page ? (404 ?) *)
  then
    let content =
      div ~a:[a_class ["ol_error"]] [
        h1 [pcdata "You're not allowed to access to this page."];
        a ~a:[a_class ["ol_link_error"]]
          ~service:Eba_services.main_service
          [pcdata "back"]
          ()
      ]
    in
    Lwt.return
      (page_container [content])
  else
    lwt content = admin_page_content user set_group_of_user_rpc get_groups_of_user_rpc in
      Lwt.return (page_container content)
