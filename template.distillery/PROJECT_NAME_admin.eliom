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
              Ew_completion.li ~value:s [ pcdata s ])
           (l)
       ) : Html5_types.li elt list) (* FIXME *))

let create_account_rpc =
  server_function
    Json.t<string>
    (Ebapp.Session.connected_rpc
       (fun _ email ->
          lwt is_preregistered = %%%MODULE_NAME%%%.is_preregistered in
          lwt _ =
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
  let create_puser_box email =
    div [
      span [
        pcdata email;
      ];
    ]
  in
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

  let handler user _ _ =
    lwt preregister_section =
      create_preregister_section ()
    in
    %%%MODULE_NAME%%%_container.page (Some user) [
      preregister_section;
    ]

let () =
  Ebapp.App.register
    %%%MODULE_NAME%%%_services.admin_service
    (Ebapp.Page.connected_page ~allow:[%%%MODULE_NAME%%%_groups.admin] handler);

