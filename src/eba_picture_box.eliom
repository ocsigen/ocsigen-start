{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

{shared{
  let string_uri path =
    make_string_uri ~absolute:true ~service:(Eliom_service.static_dir ()) path
}}

{client{
  let current_src_picture = ref (Js.string "")

  let update_pictures dname fname =
    let oldpic = !current_src_picture in
    let newpic = Js.string (string_uri (dname @ [fname])) in
    current_src_picture := newpic;
    let pics =
      Dom_html.document##body##querySelectorAll
        (Js.string ("."^Eba_user.cls_avatar))
    in
    for i = 0 to pics##length - 1 do
      let img = Js.Unsafe.coerce (Eba_misc.of_opt (pics##item(i))) in
      Firebug.console##log(oldpic);
      Firebug.console##log(img##src);
      if img##src = oldpic
      then img##src <- newpic
    done

  let _ =
    lwt () = Lwt_js_events.request_animation_frame () in
    let default_picture =
      Dom_html.document##body##querySelector
        (Js.string ("div.ol_identity img."^Eba_user.cls_avatar))
    in
    let src =
      Js.Opt.case default_picture
        (fun () -> Js.string "")
        (fun v -> (Js.Unsafe.coerce v)##src);
    in
    current_src_picture := src;
    Lwt.return ()
}}

{shared{
  type crop_param_t = (Eba_user.shared_t * string list * string * (int * int * int * int)) deriving (Json)
}}

{server{
  let crop_on_server =
    server_function
      Json.t<crop_param_t>
      (fun (user, dname, fname, (x,y,width,height)) ->
         let path = List.fold_left (fun a b -> a^"/"^b) "./static" dname in
         let path = path^"/"^fname in
         let im = Magick.read_image ~filename:path in
         Magick.Imper.crop im ~x ~y ~width ~height;
         Magick.write_image im ~filename:path;
         (* We mark the as used to prevent an automatic remove from
          * the cleaner thread *)
         lwt () = Ew_dyn_upload.mark_as_used fname in
         (*lwt () = Eba_db.set_pic (Eba_common0.id_of_user user) fname in*)
         Lwt.return ())
}}

let create user =
  let dbox = D.div ~a:[a_class ["ol_upload_pic"]] [pcdata "Upload picture"] in
  ignore ({unit{
    ignore (object(self)
      (* and Ojw_popup provides some setters to change the content of
       * the popup. We're going to change the content of it at each
       * different steps (select a photo, downloading, cropping). *)
      inherit Ojw_popup.popup
                    ~width:700
                    ~set:(Eba_site_widgets.global_widget_set)
                    (To_dom.of_div %dbox) as super


      val img' = D.img ~src:(string_uri [""]) ~alt:"" ()

      (* when leaving the popup *)
      method on_unpress =
        let jimg = To_dom.of_img img' in
        jimg##onload <- Dom.handler (fun _ -> Js.bool true);
        jimg##src <- Js.string "";
        Lwt.return ()

      method on_press =
        lwt () = super#on_press in
        let inp = D.Raw.input ~a:[a_input_type `File] () in
        let uploading =
          D.Raw.input
            ~a:[a_input_type `Submit; a_value "Uploading your profile photo"]
            ()
        in
        let cancel =
          D.Raw.input
            ~a:[a_input_type `Button; a_value "Cancel"]
            ()
        in
        self#set_header [
          To_dom.of_p (p [pcdata "Change your photo:"])
        ];
        self#set_footer [
          To_dom.of_element uploading;
          To_dom.of_element cancel;
        ];
        self#set_body [
          To_dom.of_element (pcdata "Select your photo:");
          To_dom.of_element inp;
        ];
        let create_div_error content =
          let p_content = List.map (fun c -> pcdata c) content in
          div
            ~a:[a_class ["eba_upload_error"]]
            [
              h3 [pcdata "Something went wrong."];
              p p_content
            ]
        in
        (* Close the popup on cancel *)
        ignore (object
                  inherit Ojw_button.button ~button:(To_dom.of_element cancel) ()
                  method on_press = self#close
                end);
        let crop =
          D.Raw.input ~a:[a_input_type `Submit; a_value "Set as profile photo"] ()
        in
        let crop_butt =
          (* We create a button which will store some important data
           * to crop the image on the server side *)
          object
            inherit Ew_button.button ~button:crop ()

            val mutable dname' = []
            val mutable fname' = ""
            val mutable popup_body = []
            val mutable crop_prop' = None

            method set_dir dname = dname' <- dname
            method set_filename fname = fname' <- fname
            method set_crop_prop p =
              match p with
                | None -> crop_prop' <- None
                | Some p -> crop_prop' <- Some p
            method set_body_popup b = popup_body <- b

            method on_press =
              match crop_prop' with
                | None ->
                    let error =
                      create_div_error [
                        "You have to select an area of the photo !";
                      ]
                    in
                    self#set_body ((To_dom.of_element error)::popup_body);
                    self#update;
                    press_state <- false;
                    Lwt.return ()
                | Some prop -> begin
                    lwt () = %crop_on_server (%user, dname', fname', prop) in
                    (* update all pics on the page? *)
                    update_pictures dname' fname';
                    let text =
                      p [pcdata "You profile's photo has been changed !"]
                    in
                    self#set_body [
                      To_dom.of_element text;
                    ];
                    self#set_footer [
                      To_dom.of_element cancel;
                    ];
                    self#update;
                    Lwt.return ()
                  end

          end
        in
        let download_and_crop file =
            (* We have already created our dynamic upload service.
             * Here we're going to upload dynamically upload a file
             * using our service. *)
            Ew_dyn_upload.dyn_upload
              ~service:(%Eba_services.crop_service)
              ~file
              (fun dname fname ->
                 let jimg = To_dom.of_img img' in
                 crop_butt#set_dir dname;
                 crop_butt#set_filename fname;
                 let image_on_load () =
                   let on_select c =
                     crop_butt#set_crop_prop (Some (c##x,c##y,c##w,c##h))
                   in
                   let on_release _ =
                     crop_butt#set_crop_prop None
                   in
                   (* We use an wrapper, because jcrop is going to
                    * wrap our image into a div in display:block
                    * and we want to center our image, using an
                    * inline-block property *)
                   let inline_wrapper =
                     D.div ~a:[a_style "display: inline-block"] [img']
                   in
                   crop_butt#set_body_popup [
                     To_dom.of_element inline_wrapper;
                   ];
                   self#set_body [
                     To_dom.of_element inline_wrapper;
                   ];
                   self#set_footer [
                     To_dom.of_element crop;
                     To_dom.of_element cancel;
                   ];
                   ignore (new Ojw_jcrop.jcrop
                             ~aspect_ratio:1.0
                             ~set_select:(100, 100, 50, 50)
                             ~on_release
                             ~on_select
                             jimg);
                   (* Update the popup because the image has been
                    * loaded and the popup's height have changed *)
                   self#update;
                   Js.bool true
                 in
                 (* Will be called when the image will be loaded *)
                 jimg##onload <- Dom.handler
                                   (fun _ -> if self#pressed
                                      then image_on_load ()
                                      else Js.bool false);
                 jimg##src <- Js.string (string_uri (dname @ [fname]));
                 Lwt.return ())
        in
        (* Add a spinner icon when uploading the picture *)
        ignore (object
          inherit Ew_button.button ~button:uploading ()

          method on_press =
            Js.Optdef.case ((To_dom.of_input inp)##files)
              (fun _ -> Lwt.return ())
              (fun files ->
                 Js.Opt.case (files##item(0))
                   (fun _ ->
                      let error =
                        create_div_error [
                          "You have to select a file !";
                        ]
                      in
                      self#set_body [
                        To_dom.of_element error;
                        To_dom.of_element (pcdata "Select your photo:");
                        To_dom.of_element inp;
                      ];
                      press_state <- false;
                      self#update;
                      Lwt.return ())
                   (fun file ->
                      self#set_body [
                        let icon =
                          D.i
                            ~a:[a_class ["icon-spinner"; "icon-spin"]]
                            []
                        in
                        To_dom.of_element icon
                      ];
                      self#set_footer [
                        To_dom.of_element cancel;
                      ];
                      (* Last step *)
                      try_lwt
                        download_and_crop file
                      with
                        | Eliom_lib.Exception_on_server s ->
                            (* reset uploading button before insert it into
                             * the popup (because it is pressed at this
                             * moment, so we have to unpress it) *)
                            press_state <- false;
                            let error =
                              create_div_error [
                                "Make sure to have upload ";
                                "file with a valid extentions (png, jpg)"
                              ]
                            in
                            self#set_header [
                              To_dom.of_p (p [pcdata "Change your photo:"])
                            ];
                            self#set_footer [
                              To_dom.of_element uploading;
                              To_dom.of_element cancel;
                            ];
                            self#set_body [
                              To_dom.of_element error;
                              To_dom.of_element (pcdata "Select your photo:");
                              To_dom.of_element inp;
                            ];
                            self#update;
                            Lwt.return ()))
                end);
        Lwt.return ()
   end)
}});
dbox
