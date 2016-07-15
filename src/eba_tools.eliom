
let%shared popup_button ~button_name ~popup_content = Eliom_content.Html.D.(
  let button =
    Form.input
      ~a:[a_class ["eba_popup_button"]]
      ~input_type:`Submit
      ~value:button_name
      Form.string
  in
  ignore
    [%client
        (Lwt.async (fun () ->
          Lwt_js_events.clicks
            (Eliom_content.Html.To_dom.of_element ~%button)
            (fun _ _ ->
              let%lwt _ =
                Ot_popup.popup
                  ~close_button:[Eliom_content.Html.D.pcdata "close"]
                  (fun _ -> Lwt.return ~%popup_content)
              in
              Lwt.return ()))
           : _)
    ];
  button
)
