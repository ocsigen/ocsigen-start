{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.D
}}

{client{
  let (!>) = To_dom.of_element
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

{shared{
  let clear_both () = div ~a:[a_style "clear: both"] []
}}

(* Preregister section : begin *)

let refresh_preregister_rpc =
  server_function
    Json.t<int * string>
    (fun (limit, pattern) ->
       lwt l =
         %%%MODULE_NAME%%%_db.User.get_preregistered_users
           ~limit:(0L, (Int64.of_int limit))
           ~pattern
           ()
       in
       Lwt.return ((
         List.map
           (fun s ->
              Ew_completion.li ~value_to_match:s ~value:s [ pcdata s ])
           (l)
       ) : Html5_types.li elt list) (* FIXME *))

let create_account_rpc =
  server_function
    Json.t<string>
    (Ebapp.Session.connected_rpc
       (fun _ email ->
          lwt is_preregistered = %%%MODULE_NAME%%%_user.is_preregistered email in
          if is_preregistered then begin
            lwt _ = %%%MODULE_NAME%%%.sign_up_handler' () email in
            Lwt.return ()
          end else Lwt.return ()
       )
    )

{client{
  let create_account_box email =
    let account_butt = Raw.button [pcdata "Create"] in
    let account_box =
      div ~a:[a_class ["eba_preregister-box"]] [
        span ~a:[a_user_data "value" email] [
          pcdata email;
        ];
        account_butt;
        clear_both ();
      ]
    in
    let account_box' = !> account_box in
    on_click account_butt
      (fun _ _ ->
         lwt _ = %create_account_rpc email in
         Js.Opt.iter (account_box'##parentNode)
           (fun parent ->
              Dom.removeChild parent account_box');
         Lwt.return ());
    account_box
}}

let create_preregister_section () =
  let create_search () =
    let inpt = string_input ~input_type:`Text ~a:[a_placeholder "Enter user.."] () in
    let inpt_buf =
      div ~a:[a_class ["eba_preregister-area"]] [
      ]
    in
    let _, inpt_dd =
      Ew_completion.completion
        ~limit:5
        ~adaptive:true
        ~clear_input_on_confirm:true
        ~refresh:{Ew_completion.refresh_fun{(fun limit pattern ->
          %refresh_preregister_rpc (limit, pattern)
        )}}
        ~on_confirm:{Ew_completion.on_confirm_fun{(fun email ->
            let inpt_buf' = !> %inpt_buf in
            (* Check if the entered user has already been added to the page *)
            Js.Opt.case (inpt_buf'##querySelector(Js.string ("span[data-value='"^email^"']")))
              (fun () ->
                 Manip.appendChild %inpt_buf (create_account_box email))
              (ignore);
            Lwt.return ()
        )}}
        (inpt)
        (D.ul [])
    in
    div [
      (inpt :> Html5_types.div_content elt);
      (inpt_dd :> Html5_types.div_content elt);
      inpt_buf;
    ]
  in
  Lwt.return (div ~a:[a_id "preregister"] [
    create_search ();
  ])

(* Preregister section : end *)

(* User settings section : begin *)

let uid_of_email_rpc =
  server_function
    Json.t<string>
    (fun email ->
       lwt uid = %%%MODULE_NAME%%%_user.uid_of_email email in
       %%%MODULE_NAME%%%_user.user_of_uid uid)

let refresh_users_rpc =
  server_function
    Json.t<int * string>
    (fun (limit, pattern) ->
       lwt l =
         %%%MODULE_NAME%%%_db.User.get_users
           ~limit:(0L, (Int64.of_int limit))
           ~pattern
           ()
       in
       (Lwt_list.map_s
           (fun (uid,fn,ln,avatar) ->
              lwt email = %%%MODULE_NAME%%%_user.email_of_uid uid in
              Lwt.return (
                Ew_completion.li
                ~value:email
                ~value_to_match:(fn^" "^ln^" "^email)
                [
                  pcdata fn;
                  pcdata " ";
                  pcdata ln;
                  pcdata " - ";
                  pcdata email;
                ]))
           (l)
        : Html5_types.li elt list Lwt.t) (* FIXME *))

(* SECURITY: Should we use uid here ? *)
let add_in_group_rpc =
  server_function
    Json.t<int64 * %%%MODULE_NAME%%%_groups.t>
    (fun (uid,group) ->
       %%%MODULE_NAME%%%_groups.add_user_in_group ~group ~userid:uid)

(* SECURITY: Should we use uid here ? *)
let remove_from_group_rpc =
  server_function
    Json.t<int64 * %%%MODULE_NAME%%%_groups.t>
    (fun (uid,group) ->
       %%%MODULE_NAME%%%_groups.remove_user_in_group ~group ~userid:uid)

(* SECURITY: Should we use uid here ? *)
let get_groups_rpc =
  server_function
    Json.t<int64>
    (fun uid ->
       lwt groups = %%%MODULE_NAME%%%_groups.all () in
       Lwt_list.map_s
         (fun group ->
            lwt is_in = %%%MODULE_NAME%%%_groups.in_group ~group ~userid:uid in
            Lwt.return (is_in, group))
         (groups))

{client{
  let create_user_box email user =
    let open %%%MODULE_NAME%%%_groups in
    let open %%%MODULE_NAME%%%_user in
    let create_group_row (is_in,group) =
      let desc = match group.desc with
        | None -> "No description given."
        | Some desc -> desc
      in
      let checkbox =
        Raw.input
          ~a:(a_input_type `Checkbox::(if is_in then [a_checked `Checked] else []))
          ();
      in
      let checkbox' = To_dom.of_input checkbox in
      Lwt.async (fun () ->
        Lwt_js_events.clicks checkbox'
          (fun _ _ ->
             if checkbox'##checked = Js._true then begin
               %add_in_group_rpc (user.uid,group);
             end else begin
               %remove_from_group_rpc (user.uid,group);
             end
          );
      );
      tr [
        td [
          checkbox;
        ];
        td [
          pcdata (group.name^":");
        ];
        td [
          pcdata desc;
        ];
      ]
    in
    lwt groups = %get_groups_rpc user.uid in
    let groups_rows =
      List.map
        create_group_row
        groups
    in
    let create_info_row title value =
      tr [
        td [
          strong [pcdata title];
        ];
        td [
          pcdata value;
        ];
      ]
    in
    Lwt.return (
      div ~a:[a_class ["eba_admin_user_box"]] [
          table ~a:[a_class ["eba_admin_user_desc"]] [
            create_info_row "First Name:" user.fn;
            create_info_row "Last Name:" user.ln;
            create_info_row "Full Name:" (user.fn^" "^user.ln);
            create_info_row "E-mail:" email;
          ];
          table ~a:[a_class ["eba_admin_user_groups"]] (
            [
              tr [
                th [strong [pcdata "In group"]];
                th [strong [pcdata "Group's name"]];
                th [strong [pcdata "Group's description"]];
              ];
            ] @ groups_rows;
          );
      ];
    )
}}

let create_user_section () =
  let create_search () =
    let inpt = string_input ~input_type:`Text ~a:[a_placeholder "Enter user.."] () in
    let inpt_buf =
      div ~a:[a_class ["eba_user_settings-area"]] [
      ]
    in
    let _, inpt_dd =
      Ew_completion.completion
        ~limit:5
        ~adaptive:true
        ~clear_input_on_confirm:true
        ~refresh:{Ew_completion.refresh_fun{(fun limit pattern ->
          %refresh_users_rpc (limit, pattern)
        )}}
        ~on_confirm:{Ew_completion.on_confirm_fun{(fun email ->
            lwt user = %uid_of_email_rpc email in
            let inpt' = To_dom.of_input %inpt in
            let inpt_buf' = !> %inpt_buf in
            inpt'##disabled <- Js._true;
            lwt user_box = create_user_box email user in
            Manip.appendChild %inpt_buf user_box;
            Lwt.return ()
        )}}
        (inpt)
        (D.ul [])
    in
    div [
      (inpt :> Html5_types.div_content elt);
      (inpt_dd :> Html5_types.div_content elt);
      inpt_buf;
    ]
  in
  Lwt.return (div ~a:[a_id "user-settings"] [
    create_search ();
  ])

(* User settings section : end *)

let handler user _ _ =
  lwt preregister_section =
    create_preregister_section ()
  in
  lwt user_section =
    create_user_section ()
  in
  %%%MODULE_NAME%%%_container.page (Some user) [
    div ~a:[a_id "eba_admin"] [
      preregister_section;
      user_section;
    ];
  ]

let () =
  Ebapp.App.register
    %%%MODULE_NAME%%%_services.admin_service
    (Ebapp.Page.connected_page ~allow:[%%%MODULE_NAME%%%_groups.admin] handler);

