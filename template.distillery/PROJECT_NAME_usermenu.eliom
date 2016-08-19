
let%shared disconnect_button () = Eliom_content.Html.D.(
  Form.post_form ~service:Os_services.disconnect_service
    (fun _ -> [
         Form.button_no_value
           ~a:[ a_class ["button"] ]
           ~button_type:`Submit
           [Ot_icons.F.signout (); pcdata "Logout"]
       ]) ()
)

let%shared settings_button () = Eliom_content.Html.D.(
    let button =
      button ~a:[a_class ["btn";"button"]] [pcdata "Settings"]
    in
    ignore
      [%client
          (Lwt.async (fun () ->
            Lwt_js_events.clicks
              (Eliom_content.Html.To_dom.of_element ~%button)
              (fun _ _ ->
		Eliom_client.change_page
		  ~service:%%%MODULE_NAME%%%_services.settings_service () ()
	      )
	   )
             : _)
      ];
    div [button]
)

