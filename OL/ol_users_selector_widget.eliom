(* Copyright Séverine Maingaud *)

{client{
open Eliom_content.Html5
open Eliom_content.Html5.F
open Ol_selection_widgets
open Ol_users_base_widgets





module MakeSelectionWidget(BW:BaseWidgets) =
  struct

    let member_selector ?cls_widget ?cls_send ?cls_cancel ?cls_buttons
        ?cls_selected ?cls_removebutton ?cls_tbox ?cls_completion_input
        send_handler msg widget_opened =

      let print a = span [BW.print_avatar a ; BW.print_name a] in

      let build_licontent  get_string pattern m index =
        let good_length s l  =
          let s = Js.to_string (Ew_accents.removeDiacritics (Js.string s)) in
          String.length s = l
        in

        (* translate_to_index s p where s is a accented string, translate
           the index p in s without accents into the corresponding index in s *)
        let translate_to_index s p =
          let rec aux i =
            if
              i = String.length s ||
              let c = Char.code s.[i] in
              ((c < 0x80 || 0xBF < c) && good_length (String.sub s 0 i) p)
            then i
            else aux (i+1)
          in
          aux 0
        in
        let name = (get_string m) in
        let pattern_length = String.length pattern in
        let suffix_index = index + pattern_length in
        let index = translate_to_index name index in
        let suffix_index = translate_to_index name suffix_index in
        let suffix_length = (String.length name) - suffix_index in
        let prefix,matched,suffix =
          String.sub name 0 index,
          String.sub name index (suffix_index - index),
          String.sub name suffix_index suffix_length
        in
        [span ~a:[a_class [BW.class_of_memberbox m]]
            [BW.print_member_avatar m ;
             span ~a:[a_class [BW.class_of_member m]]
               [pcdata prefix ; b [pcdata matched] ; pcdata suffix]]]
      in



      let t_of_data d = BW.Member d in
      let t_of_string s = BW.Invited s in
      let get_string = BW.name_of_member in
      let get_from_server = BW.get_memberlist in
      let remove = BW.remove in
      let contains = BW.contains in
      let switch_to_restrictive s = not (BW.might_be_mail s) in
      let launch_selector = launch_selection_by_completion ?cls_removebutton
          ?cls_tbox ?cls_selected ?cls_completion_input ~msg ~print ~remove
          ~contains ~get_string ~get_from_server ~build_licontent ~t_of_data
          ~t_of_string ~switch_to_restrictive ()
      in

      selector_widget
        ?cls_widget ?cls_send ?cls_cancel ?cls_buttons ?cls_selected
        launch_selector send_handler widget_opened
  end
}}
