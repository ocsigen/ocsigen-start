(* Copyright Vincent Balat *)

(** This module defines specific Ol site widgets *)

{shared{
open Eliom_content
open Eliom_content.Html5
open Eliom_content.Html5.F
}}

let class_globalpart = "ol_globalpart"
let class_identity = "ol_identity"
let class_mainpart = "ol_mainpart"
let class_main_infobox = "ol_main_infobox"

{client{

  let info ?important ?class_ ?timeout msg =
    Eba_misc.log msg
(*INFOBOX
    Lwt.async
      (fun () -> lwt infobox_o = infobox_o_t in
                 infobox_o#info ?class_ ?important ?timeout msg;
                 Lwt.return ())
*)

}}

let main_title capitalized_app_name =
  let title =
    Eliom_content.Html5.Id.create_global_elt
      (D.h1 [a ~service:Eba_services.main_service
                [pcdata capitalized_app_name] ()])
  in
  ignore {unit{
    Eliom_client.onload
      (fun () ->
        let t = To_dom.of_h1 %title in
        Lwt_js_events.async (fun () ->
          Lwt_js_events.clicks t (fun ev _ ->
            Dom.preventDefault ev;
            info "Ocsigen Labs";
            Lwt.return ())))
  }};
  title

let logout_button () =
  (* let b = D.div ~a:[a_class ["ol_logout_button"]] [pcdata "O"] in *)
  let b = D.div ~a:[a_class ["ol_logout_button"]]
    [i ~a:[a_class ["icon-signout"]] []]
  in
  ignore {unit{
    Lwt_js_events.async (fun () ->
      Lwt_js_events.clicks (To_dom.of_div %b)
        (fun _ _ -> Eliom_client.change_page %Eba_services.logout_service () ()))
    }};
  b

{client{

let current_pic = ref (Js.string "")

let _ =
  lwt () = Lwt_js_events.request_animation_frame () in
  current_pic := Js.Opt.case
    (Dom_html.document##body##querySelector
       (Js.string ("div.ol_identity img."^Eba_common0.cls_avatar)))
    (fun () -> Js.string "")
    (fun v -> (Js.Unsafe.coerce v)##src);
 Lwt.return ()

let update_pics newpic =
  let oldpic = !current_pic in
  let newpic =
    Js.string (Eba_common0.make_pic_string_uri ~absolute:true newpic) in
  current_pic := newpic;
  let pics =
    Dom_html.document##body##querySelectorAll
      (Js.string ("."^Eba_common0.cls_avatar))
  in
  for i = 0 to pics##length - 1 do
    let img = Js.Unsafe.coerce (Eba_misc.of_opt (pics##item(i))) in
    Firebug.console##log(oldpic);
    Firebug.console##log(img##src);
    if img##src = oldpic
    then img##src <- newpic
  done


let upload_pic_form me () =
  let file = D.Raw.input ~a:[a_input_type `File] () in
  let thesubmit = D.Raw.input ~a:[a_input_type `Submit; a_value "Send"] () in
  Lwt_js_events.(
    async (fun () ->
      clicks (To_dom.of_input thesubmit)
        (fun _ _ ->
          Js.Optdef.case ((To_dom.of_input file)##files)
            Lwt.return
            (fun files ->
              Js.Opt.case (files##item(0))
                Lwt.return
                (fun file ->
                  lwt newpic = Eliom_client.call_caml_service
                    ~service:%Eba_services.pic_service
                    () file
                  in
                  (* close form *)
                  me#unpress;
                  (* update all pics on the page? *)
                  update_pics newpic;
                  Lwt.return ()
                )
        ))));
  [pcdata "Upload a picture:";
   file;
   thesubmit]
}}

{client{
let settings_set = Ew_buh.new_radio_set ()
}}

let upload_pic_button () =
  let d = D.div ~a:[a_class ["ol_upload_pic"]] [pcdata "Upload picture"] in
  ignore {unit{
    let d = To_dom.of_div %d in
    ignore (object (me)
      inherit [ Html5_types.div_content_fun ] Ew_buh.alert
        ~set:settings_set
        ~class_:["ol_upload_pic_form"]
        ~button:d
(*        ~parent_node:(Eba_misc.of_opt d##parentNode) *)
        ()
      method get_node = Lwt.return (upload_pic_form me ())
    end)
    }};
  d

let () =
  Eba_settings.push_generator (fun () -> Lwt.return [logout_button ()])


let userbox user =
  lwt settings = Eba_settings.create () in
  Lwt.return
    (div ~a:[a_class [class_identity]] [
      Eba_common0.print_user_avatar user;
      upload_pic_button ();
      Eba_common0.print_user_name user;
      settings
    ])

let globalpart main_title user =
(*INFOBOX
  let infobox = Eliom_widgets.infobox_elts ~class_:[class_main_infobox] () in
  ignore
    {unit{ REIMPLEMENT
        (new Eliom_widgets.infobox ~multiline:true ~timeout:10. %infobox)}};
*)
  lwt content = match user with
    | Some user ->
      lwt ubox = userbox user in
      Lwt.return [ubox(*; infobox *)]
    | None ->
      lwt cbox = Eba_base_widgets.login_signin_box () in
      Lwt.return [cbox(* infobox *)]
  in
  Lwt.return
    (aside ~a:[a_class [class_globalpart]]
       (main_title
        ::content))


let mainpart ?(class_=[]) l = div ~a:[a_class (class_mainpart::class_)] l
