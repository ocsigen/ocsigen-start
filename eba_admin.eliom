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

module Make(M : sig
  module Groups : Eba_groups.T
end)
=
struct
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

  let switch_on_mode =
    server_function
      Json.t<Eba_site.state_t>
      (fun state -> Eba_site.set_state state)

  let admin_page_content user set_group_of_user_rpc get_groups_of_user_rpc =
    let open Eba_base_widgets in
    lwt state = Eba_site.get_state () in
    let enable_if b =
      if b then "ol_current_state"
      else ""
    in
    let users_box = D.div [] in
    let widget = D.div [] in
    (* I create a dummy button because the completion widget need it,
     * but it seems to be not used at all by the widget so.. *)
    let dummy_data = D.h2 [pcdata "dummy"] in
    let dummy_button = {button_t{
      new Ew_button.button
        ~button:%dummy_data
        ()
    }} in
    let make_rb pressed desc =
      D.raw_input
        ~a:(if pressed then [a_checked `Checked] else [])
        ~input_type:`Radio
        ~name:"state"
        ~value:desc
        (),
      pcdata desc
    in
    let rb1,rb_desc1 =
      make_rb
        (state = Eba_site.Close)
        "allow pre-registration of users"
    in
    let rb2,rb_desc2 =
      make_rb
        (state = Eba_site.Open)
        "allow registration of users"
    in
    ignore {unit{
      ignore (Lwt_js_events.clicks (To_dom.of_element %rb1)
                (fun _ _ ->
                   lwt () = (%switch_on_mode (Eba_site.Close)) in
                   Lwt.return ()));
      ignore (Lwt_js_events.clicks (To_dom.of_element %rb2)
                (fun _ _ ->
                   lwt () = (%switch_on_mode (Eba_site.Open)) in
                   Lwt.return ()));
    }};
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
      rb1; rb_desc1;
      br ();
      rb2; rb_desc2;
      hr ();
      widget;
      users_box
    ]

  let admin_service_handler
        page_container
        main_title
        get_user
        set_group_of_user_rpc
        get_groups_of_user_rpc
        uid () () =
    lwt user = get_user uid in
    lwt admin = M.Groups.admin in
    lwt is_admin = (M.Groups.in_group ~userid:uid ~group:admin) in
    if not is_admin
    then
      lwt gblp = Eba_site_widgets.globalpart main_title (Some user) in
      let msg = [p [pcdata "you are not allowed to access to this page"]] in
      let url =
        Eliom_content.Html5.F.make_string_uri
          ~service:Eba_services.main_service
          ()
      in
      ignore {unit{
        ignore (
          lwt () = Lwt_js.sleep 2. in
          Dom_html.window##location##href <- (Js.string %url);
          Lwt.return ()
        )
      }};
      Lwt.return
        (page_container ([gblp] @ msg))
    else
      lwt content = admin_page_content user set_group_of_user_rpc get_groups_of_user_rpc in
      lwt gblp = Eba_site_widgets.globalpart main_title (Some user) in
      Lwt.return
        (page_container (gblp::content))

end
