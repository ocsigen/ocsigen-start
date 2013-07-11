{shared{
  open Eliom_content
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

module Eba_fm = Eba_flash_message

(** This module is used for preregistration system on your website.
  * Severals functions are provided in Eba_db:
  * - all_preregistered: return the list of all the preregistered emails
  * - is_preregistered: return true if the email is already preregistered
  *
  * There is a table named: "preregister" which used only one column "email"
  *)

(* this box is used by ol_base_widget.eliom to display
 * a box with an input to preregister an email *)
let preregister_box service =
  let r = ref None in
  let f = D.post_form
    ~service
    (fun (m) ->
      let i = D.string_input
        ~a:[a_placeholder "e-mail address";
            a_required `Required]
        ~input_type:`Email ~name:m ()
      in
      r := Some i;
      [i;
       string_input
         ~input_type:`Submit ~value:"register" ();
      ])
    ()
  in
  f, match !r with Some i -> i | None -> failwith "preregister_box"

let preregister_action () (m) =
  lwt b = Eba_db.is_registered_or_preregistered m in
  Eba_misc.log (string_of_bool b);
  match b with
    | false ->
        Eba_misc.log "NON PREREGISTERED";
        Eba_db.new_preregister_email m
    | true ->
        Eba_misc.log "ALREADY PREREGISTERED";
        Eba_fm.set_flash_msg (Eba_fm.User_already_preregistered m)

