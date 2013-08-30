{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

{client{
  let create_user_settings_box_content
        get_groups_of_user_rpc
        set_group_of_user_rpc
        new_search_but
        u
        =
    let uid = Eba_shared.User.uid_of_user u in
    let radio_button_of (group, in_group) =
      let rb =
        D.raw_input
          ~a:(if in_group then [a_checked `Checked] else [])
          ~input_type:`Checkbox
          ~value:(Eba_shared.Groups.name_of_group group)
          ()
      in
      Lwt.async
        (fun () ->
           let rb = (To_dom.of_input rb) in
           Lwt_js_events.clicks rb
             (fun _ _ ->
                let checked = Js.to_bool rb##checked in
                set_group_of_user_rpc
                  (uid, (checked, group))));
      let group_desc = match Eba_shared.Groups.desc_of_group group with
        | None -> "no description given"
        | Some d -> d
      in
      div ~a:[a_class ["eba_admin_group_of_user"]]
        [
          b [pcdata (Eba_shared.Groups.name_of_group group)];
          rb;
          hr ();
          p [pcdata group_desc];
        ]
    in
    lwt groups = get_groups_of_user_rpc uid in
    let rbs = List.map (radio_button_of) (groups) in
    let open Eba_shared.User in
    Lwt.return
      (div ~a:[a_class ["eba_admin_user_information"]] [
         img
           ~alt:(fullname_of_user u)
           ~src:(make_avatar_uri (avatar_of_user u))
           ();
         table
           (tr [
             td [pcdata "User ID:"];
             td [pcdata (string_of_int (Int64.to_int uid))]])
           [
             tr [
               td [pcdata "Firstname:"];
               td [pcdata (firstname_of_user u)]
             ];
             tr [
               td [pcdata "Lastname:"];
               td [pcdata (lastname_of_user u)]
             ];
           ]
       ]
       ::div [
         new_search_but
       ]
       ::rbs)
}}

module Make(M : sig
  module User : Eba_user.T
  module State : Eba_state.T
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

  let admin_page_content
        user
        set_group_of_user_rpc
        get_users_from_completion_rpc
        get_groups_of_user_rpc
    =
    lwt state = M.State.get_website_state () in
    let widget = D.div [] in
    (* I create a dummy button because the completion widget need it,
     * but it seems to be not used at all by the widget so.. *)
    let make_rb st =
      let rbname = M.State.name_of_state st in
      let rbdesc = M.State.desc_of_state st in
      let rb =
        D.raw_input
          ~a:(if (state = st) then [a_checked `Checked] else [])
          ~input_type:`Radio
          ~name:"state"
          ~value:rbdesc
          ()
      in
      let f = M.State.fun_of_state st in
      ignore {unit{
        ignore
          (Lwt_js_events.clicks (To_dom.of_element %rb)
             (fun _ _ -> %f ()))
      }};
      D.div [
        rb;
        pcdata rbdesc;
        hr ();
      ]
    in
    let rbs = List.map (fun st -> make_rb st) (M.State.all ()) in
    let inp =
      D.raw_input
        ~a:[a_placeholder "enter user name"; a_id "admin_completion"]
        ~input_type:`Text
        ()
    in
    let new_search_but =
      D.raw_input
        ~input_type:`Button
        ~value:"new search"
        ()
    in
    let admin_sandbox =
      D.div ~a:[a_class ["eba_admin_sandbox"]]
        [
          inp
        ]
    in
    let comp_w = {(Ew_completion.completion_t){
      let on_confirm u =
        lwt div_ct =
          create_user_settings_box_content
            %get_groups_of_user_rpc
            %set_group_of_user_rpc
            %new_search_but
            u
        in
        Eliom_content.Html5.Manip.removeAllChild %admin_sandbox;
        Eliom_content.Html5.Manip.appendChild
          %admin_sandbox
          (D.div ~a:[a_class ["eba_admin_user_box"]] div_ct);
        Lwt.return ()
      in
      let on_show u =
        [
          img
            ~a:[a_class ["eba_avatar"]]
            ~alt:(Eba_shared.User.fullname_of_user u)
            ~src:(Eba_shared.User.make_avatar_uri (Eba_shared.User.avatar_of_user u))
            ();
          span
            ~a:[a_class ["eba_username"]]
            [pcdata (Eba_shared.User.fullname_of_user u)]
        ]
      in
      new Ew_completion.completion
                ~input:%inp
                ~to_string:Eba_shared.User.fullname_of_user
                ~on_refresh:%get_users_from_completion_rpc
                ~on_confirm
                ~on_show
                ()
    }} in
    ignore {unit{
      Eba_view.Helper.on_click %new_search_but
        (fun e ->
           %comp_w#clear;
           %comp_w#clear_input;
           Eliom_content.Html5.Manip.removeAllChild %admin_sandbox;
           Eliom_content.Html5.Manip.appendChild %admin_sandbox %inp;
           Lwt.return ())
    }};
    Lwt.return
        (rbs @ [
          widget;
          admin_sandbox;
        ])

  let admin_service_handler
        set_group_of_user_rpc
        get_users_from_completion_rpc
        get_groups_of_user_rpc
        uid () () =
    lwt user = M.User.user_of_uid uid in
    lwt is_admin = (M.Groups.in_group ~userid:uid ~group:M.Groups.admin) in
    if not is_admin
    then
      (*
      lwt gblp = Eba_site_widgets.globalpart main_title (Some user) in
       *)
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
        (*(page_container ([gblp] @ msg))*)
        ((msg))
    else
      lwt content =
        admin_page_content
          user
          set_group_of_user_rpc
          get_users_from_completion_rpc
          get_groups_of_user_rpc
      in
      (*lwt gblp = Eba_site_widgets.globalpart main_title (Some user) in*)
        (*(page_container (gblp::content))*)
      Lwt.return [
          div ~a:[a_class ["eba_admin_page"]]
            (content)
        ]

end
