{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

{client{
  let on_click ?use_capture ?(prevent_default = false) elt f =
    Lwt_js_events.async
      (fun () ->
         Lwt_js_events.clicks ?use_capture (To_dom.of_element elt)
           (fun event thread ->
              lwt () = f event thread in
              if prevent_default then
                (Dom.preventDefault event; Dom_html.stopPropagation event);
              Lwt.return ()))
}}

let restrictive_number_input text =
  let number_input =
    D.raw_input ~input_type:`Number ~a:[a_placeholder text] ()
  in
  ignore {unit{
    Lwt_js_events.async
      (fun () ->
         Lwt_js_events.keypresses (To_dom.of_input %number_input)
           (fun e _ ->
              Js.Optdef.case (e##charCode)
                (fun _ -> Dom.preventDefault e)
                (fun c ->
                   if not (c >= 48 && c <= 57)
                   then Dom.preventDefault e
                   else ());
              Lwt.return ()))
  }};
  number_input

{shared{
  let clear () = div ~a:[a_style "clear: both"] []
}}

let create_state_section
      state
      fun_of_state
      name_of_state
      desc_of_state
      states
      =
  let make_rb st =
    let rbname = name_of_state st in
    let rbdesc = desc_of_state st in
    let rb =
      D.raw_input
        ~a:(if (state = st) then [a_checked `Checked] else [])
        ~input_type:`Radio
        ~name:"state"
        ~value:rbdesc
        ()
    in
    let f = fun_of_state st in
    ignore {unit{
      ignore
        (Lwt_js_events.clicks (To_dom.of_element %rb)
           (fun _ _ -> %f ()))
    }};
    D.div ~a:[a_class ["eba_admin_state"]] [
      rb;
      span [
        b [pcdata rbname];
        pcdata " - ";
        pcdata rbdesc;
      ];
      hr ();
    ]
  in
  D.div ~a:[
    a_id "eba_admin_state_section";
    a_class ["eba_admin_section"]
  ] (
    List.map (make_rb) (states)
  )

let create_preregister_section
      create_account_rpc
      get_preregistered_emails_rpc
      =
    let number_input = restrictive_number_input "enter a number" in
    let go_button =
      D.raw_input ~a:[a_style "float: none"] ~input_type:`Button ~value:"GO" ()
    in
    let back_button =
      D.raw_input ~input_type:`Button ~value:"Back and start a new search" ()
    in
    let create_account_button =
      D.raw_input ~input_type:`Button ~value:"Create account" ()
    in
    let select_all_button =
      D.raw_input ~input_type:`Checkbox ()
    in
    let select_all_container =
      div ~a:[a_class ["eba_admin_select_container"]] [
        select_all_button;
        b [pcdata "select all the preregistered emails"];
      ]
    in
    let container =
      D.div ~a:[a_id "eba_admin_preregister_container"] [
      ]
    in
    let header_section =
      D.div ~a:[a_class ["eba_admin_header_section"]] [
        number_input;
        go_button;
      ]
    in
    ignore {unit{
      let select_all_button' = To_dom.of_input %select_all_button in
      on_click %back_button
        (fun _ _ ->
           Manip.removeAllChild %container;
           Manip.removeAllChild %header_section;
           Manip.appendChilds %header_section
             [%number_input; %go_button];
           Lwt.return ());
      on_click %select_all_button
        (fun _ _ ->
           let checked =
             Js.to_bool select_all_button'##checked
           in
           let l = Manip.childNodes %container in
           List.iter
             (fun node -> (Js.Unsafe.coerce node)##check checked)
             (l);
           Lwt.return ());
      on_click %create_account_button
        (fun _ _ ->
           select_all_button'##checked <- Js.bool false;
           let l = Manip.childNodes %container in
           List.iter
             (fun node ->
                if (Js.Unsafe.coerce node)##checked ()
                then (Js.Unsafe.coerce node)##create_account ())
             (l);
           Lwt.return ());
      on_click %back_button
        (fun _ _ ->
           let checked = Js.to_bool select_all_button'##checked in
           let l = Manip.childNodes %container in
           List.iter
             (fun node -> (Js.Unsafe.coerce node)##check checked)
             (l);
           Lwt.return ());
    }};
    ignore {unit{
      let make_cb name =
        let cb =
          D.raw_input ~input_type:`Checkbox ~name:"preregister" ~value:name ()
        in
        let cb' = To_dom.of_input cb in
        let pr_email =
          D.div ~a:[a_class ["eba_admin_preregister_email"]] [
            cb;
            span [pcdata name]
          ]
        in
        let pr_email' = To_dom.of_div pr_email in
        let uns_pr_email = Js.Unsafe.coerce (To_dom.of_div pr_email) in
        uns_pr_email##check <-
          (fun b ->
             let cl = "eba_admin_preregister_email_selected" in
             if b
             then pr_email'##classList##add(Js.string cl)
             else pr_email'##classList##remove(Js.string cl);
             cb'##checked <- Js.bool b);
        uns_pr_email##checked <-
          (fun () -> Js.to_bool (To_dom.of_input cb)##checked);
        uns_pr_email##create_account <-
          (fun () ->
             lwt () = %create_account_rpc name in
             Manip.removeChild %container pr_email;
             Lwt.return ());
        on_click cb
          (fun _ _ ->
             uns_pr_email##check (uns_pr_email##checked ());
             Lwt.return ());
        pr_email
      in
      on_click %go_button
        (fun _ _ ->
           let n =
             int_of_string
               (Js.to_string (To_dom.of_input %number_input)##value)
           in
           lwt pr_email_l = %get_preregistered_emails_rpc n in
           Manip.appendChilds
             %container
             (List.map (make_cb) (pr_email_l));
           Manip.removeAllChild %header_section;
           Manip.appendChilds
             %header_section [
               %select_all_container;
               %back_button;
               %create_account_button;
               clear ()
             ];
           Lwt.return ())
    }};
    D.div ~a:[
      a_id "eba_admin_preregister_section";
      a_class ["eba_admin_section"]
    ] [
      header_section;
      container;
    ]

{client{
  let create_body_completion_section
        get_groups_of_user_rpc
        set_group_of_user_rpc
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
      ::(rbs @ [div ~a:[a_style "clear: both"] []]))
}}


module Make(M : sig
  module User : Eba_user.T
  module State : Eba_state.T
  module Groups : Eba_groups.T
  module Egroups : Eba_egroups.T

  val create_account_rpc
    : (string, unit)
    Eliom_pervasives.server_function

  val get_preregistered_emails_rpc
    : (int, string list)
    Eliom_pervasives.server_function

  val get_users_from_completion_rpc
    : (string, (Eba_types.User.t list))
    Eliom_pervasives.server_function

  val get_groups_of_user_rpc
    : (int64, ((Eba_types.Groups.t * bool) list))
    Eliom_pervasives.server_function

  val set_group_of_user_rpc
    : (int64 * (bool * Eba_types.Groups.t), unit)
    Eliom_pervasives.server_function


end)
=
struct
  let admin_page_content user =
    lwt state = M.State.get_website_state () in
    let state_section =
      create_state_section
        state
        M.State.fun_of_state
        M.State.name_of_state
        M.State.desc_of_state
        (M.State.all ())
    in
    let preregister_section =
      create_preregister_section
        M.create_account_rpc
        M.get_preregistered_emails_rpc
    in
    let inp =
      D.raw_input
        ~a:[a_placeholder "enter user name"; a_id "admin_completion"]
        ~input_type:`Text
        ()
    in
    let back_button =
      D.raw_input ~input_type:`Button ~value:"Back and start a new search" ()
    in
    let header_section =
      D.div ~a:[a_class ["eba_admin_header_section"]] [
        inp
      ]
    in
    let body_section = D.div [] in
    let completion_section =
      D.div ~a:[
        a_id "eba_admin_completion_section";
        a_class ["eba_admin_section"]
      ] [
        header_section;
        body_section;
      ]
    in
    let comp_w = {(Ew_completion.completion_t){
      let on_confirm u =
        lwt body_content =
          create_body_completion_section
            %M.get_groups_of_user_rpc
            %M.set_group_of_user_rpc
            u
        in
        Manip.removeAllChild %header_section;
        Manip.appendChilds %header_section [%back_button; clear ()];
        Manip.removeAllChild %body_section;
        Manip.appendChilds %body_section body_content;
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
                ~on_refresh:%M.get_users_from_completion_rpc
                ~on_confirm
                ~on_show
                ()
    }} in
    ignore {unit{
      on_click %back_button
        (fun _ _ ->
           %comp_w#clear;
           %comp_w#clear_input;
           Manip.removeAllChild %header_section;
           Manip.appendChild %header_section %inp;
           Manip.removeChild %completion_section %body_section;
           Lwt.return ())
    }};
    Lwt.return
        (state_section
         ::preregister_section
         ::[completion_section])

end
