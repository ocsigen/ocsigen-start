{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

exception Nothing

let process_rmsg f l =
  let rec aux rl = function
    | [] -> rl
    | hd::tl ->
        try aux (f hd::rl) tl
        with Nothing -> aux rl tl
  in aux [] l

let get () =
  process_rmsg
    (fun rmsg ->
       div ~a:[a_class ["rmsg"; "error"]] [
         match rmsg with
           | `User_already_exists name ->
               span [
                 pcdata "user ";
                 b [pcdata name];
                 pcdata " already exists"
               ]
           | `Activation_key_outdated ->
               span [pcdata "this activation key is outdated"]
           | `Wrong_password ->
               span [pcdata "wrong password"]
           | _ -> raise Nothing
       ])
    (Ebapp.Rmsg.Error.to_list ())
  @
  process_rmsg
    (fun rmsg ->
       div ~a:[a_class ["rmsg"; "notice"]] [
         pcdata
         (match rmsg with
            | `Preregistered -> "you have been preregistered"
            | `Activation_key_created -> "an activaton key has been created"
            | _ -> raise Nothing)
       ])
    (Ebapp.Rmsg.Notice.to_list ())
