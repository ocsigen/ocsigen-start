{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

exception Not_admin

let open_service_handler () () =
  Ol_misc.log "open";
  Ol_site.set_state Ol_site.Production

let close_service_handler () () =
  Ol_misc.log "close";
  Ol_site.set_state Ol_site.WIP

let confirm_box service value pvalue =
    post_form ~service
      (fun () ->
         [fieldset
            [p [pcdata pvalue];
             string_input
               ~input_type:`Submit
               ~value ()]
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

let admin_page_content user () =
  let open Ol_base_widgets in
  lwt state = Ol_site.get_state () in
  let states_div =
    div ~a:[a_id "ol_admin_site_state"] [
      match state with
        | Ol_site.WIP ->
            p [
              pcdata "your site is currently in state of: ";
              pcdata "WIP"
            ];
            confirm_box Ol_services.open_service
              "OPEN the website"
              "In OPEN mode, any user will be able to sign up for an account.
              This mode allow a user to retrieve his password by giving his
              email-address."
        | Ol_site.Production ->
            p [
              pcdata "your site is currently in state of: ";
              pcdata "ON PROD"
            ];
            confirm_box Ol_services.close_service
              "CLOSE the website"
              "In CLOSE mode, people will be able to pre-register an account."
    ]
  in
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
  (* this function is used to generate dynamic server_function to
   * set the new rights of a user. *)
  let set_as r =
    (* SECURITY: The [uid_of_member] is passed as parameter, but
     * we check before any update that the current user is an admin
     * to be sure that he's able to update the database. *)
    if Ol_common0.is_admin user then
      server_function
        Json.t<int64>
        (fun uid_of_member -> Ol_db.update_user_rights uid_of_member r)
    else
      server_function
        Json.t<int64>
        (fun _ -> Lwt.return ())
  in
  let set_admin = set_as Ol_common0.Admin in
  let set_beta = set_as Ol_common0.Beta in
  let set_user = set_as Ol_common0.User in
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
          let open Lwt_js_events in
          let uid_member = (MBW.id_of_member u) in
          let r = (Ol_common0.rights_to_type (MBW.rights_of_member u)) in
          let to_dom e = To_dom.of_p e in
            Lwt.async (fun () ->
                         (clicks (to_dom b1)
                            (fun _ _ ->
                               enable_with_rights Ol_common0.Admin;
                               %set_admin uid_member)));
            Lwt.async (fun () ->
                         (clicks (to_dom b2)
                            (fun _ _ ->
                               enable_with_rights Ol_common0.Beta;
                               %set_beta uid_member)));
            Lwt.async (fun () ->
                         (clicks (to_dom b3)
                            (fun _ _ ->
                               enable_with_rights Ol_common0.User;
                               %set_user uid_member)));
            enable_with_rights r;
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
                Eliom_lib.alert "%s" m
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
        div ~a:[a_id ["ol_admin_welcome"]] [
          h1 [pcdata ("welcome " ^ (Ol_common0.name_of_user user))];
        ];
        states_div;
        widget;
        users_box
      ]

let admin_service_handler page_container uid () () =
  lwt user = Ol_db.get_user uid in
  if not (Ol_common0.is_admin user)
   (* should be handle with an exception caught in the Connection_Wrapper ?
    * or just return some html5 stuffs to tell that the user can't reach this
    * page ? (404 ?) *)
  then Lwt.fail Not_admin
  else
    lwt content = admin_page_content user () in
    Lwt.return
      (page_container content)
