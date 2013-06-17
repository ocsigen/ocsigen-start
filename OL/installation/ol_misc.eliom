(* Copyright Vincent Balat *)

{shared{
open Eliom_content.Html5
open Eliom_content.Html5.F
let (>>=) = Lwt.bind

let map_option f v =
  match v with
    | None -> None
    | Some a -> Some (f a)

let map_option_lwt f v =
  match v with
    | None -> Lwt.return None
    | Some a -> f a >>= fun r -> Lwt.return (Some r)

let apply_option f v =
  match v with
    | None -> ()
    | Some a -> f a

let apply_option_lwt f v =
  match v with
    | None -> Lwt.return ()
    | Some a -> f a

let lwt_map t f g =
  match Lwt.state t with
    | Lwt.Return v -> f v
    | _ -> g ()

module List = struct

  let rec find_remove f = function
    | [] -> raise Not_found
    | a::l when f a -> a, l
    | a::l -> let b, ll = find_remove f l in b, a::ll

  let rec assoc_remove x = function
    | [] -> raise Not_found
    | (k, v)::l when x = k -> v, l
    | a::l -> let b, ll = assoc_remove x l in b, a::ll

  (* remove duplicates in a sorted list *)
  let uniq =
    let rec aux last = function
      | [] -> []
      | a::l when a = last -> aux a l
      | a::l -> a::(aux a l)
    in
    function
      | [] -> []
      | a::l -> a::(aux a l)

  let remove f m memlist =
    let rec aux acc = function
      | [] -> acc
      | a::l -> if f a m then aux acc l else aux (a::acc) l
    in
    aux [] memlist


  let contains f tlist t =
    let rec aux = function
      | [] -> false
      | r::l -> if f r t then true else aux l
    in
    aux tlist


  let union f =
    let rec aux acc = function
      | [] -> acc
      | r::l -> if f acc r
        then aux acc l else aux (r::acc) l
    in
    aux []

end

external id : 'a -> 'a = "%identity"
}}

{server{
let alert s = print_endline s
let alert_int s = print_endline (string_of_int s)
let log = alert
let log_int = alert_int
}}

{client{
let alert s = Dom_html.window##alert(Js.string s)
let alert_int s = Dom_html.window##alert(Js.string (string_of_int s))
let log s = Firebug.console##log(Js.string s)
let log_int s = Firebug.console##log(Js.string (string_of_int s))

let of_opt elt =
  Js.Opt.case elt (fun () -> failwith "of_opt") (fun elt -> elt)

let page = Dom_html.document##documentElement

module Size = struct
  let width_height, width, height =
    let wh, set_wh = React.S.create (page##clientWidth, page##clientHeight) in
    Lwt_js_events.(async (fun () -> onresizes
      (fun _ _ ->
        let w = page##clientWidth in
        let h = page##clientHeight in
        set_wh (w, h);
        Lwt.return ()
      )));
    wh,
    (React.S.l1 fst) wh,
    (React.S.l1 snd) wh

  (** [set_adaptative_width elt f] will make the width of the element
      recomputed using [f] everytime the width of the window changes. *)
  let set_adaptative_width elt f =
    (*VVV Warning: it works only because we do not have weak pointers
      on client side, thus the signal is not garbage collected.
      If Weak is implemented on client side, we must keep a pointer
      on this signal in the element *)
    ignore (React.S.map
              (fun w -> elt##style##width <-
                Js.string (string_of_int (f w)^"px")) height)

  (** [set_adaptative_height elt f] will make the width of the element
      recomputed using [f] everytime the height of the window changes. *)
  let set_adaptative_height elt f =
    (*VVV see above *)
    ignore
      (React.S.map
         (fun w -> elt##style##height <-
           Js.string (string_of_int (f w)^"px")) height)

  (* Compute the height of an element to the bottom of the page *)
  let height_to_bottom elt =
    let h = page##clientHeight in
    try
      let top = Js.to_float (of_opt (elt##getClientRects()##item(0)))##top in
      h - int_of_float top - 10
    with Failure _ -> h - 10

end

(* Returns absolute positions of an element in the window: *)
let client_top elt =
  int_of_float (Js.to_float elt##getBoundingClientRect()##top)
let client_bottom elt =
  int_of_float (Js.to_float elt##getBoundingClientRect()##bottom)
let client_left elt =
  int_of_float (Js.to_float elt##getBoundingClientRect()##left)
let client_right elt =
  int_of_float (Js.to_float elt##getBoundingClientRect()##right)

(** Check whether an element has a class *)
let has_class elt cl =
  Js.to_bool (elt##classList##contains(Js.string cl))

(** Adding a class to an element *)
let add_class str elt = elt##classList##add(Js.string str)

(** Removing a class to an element *)
let remove_class str elt = elt##classList##remove(Js.string str)

let get_element_by_id id_ =
  Js.Opt.case
    (Dom_html.document##getElementById(Js.string id_))
    (fun () -> raise Not_found)
    id

let () =
  Lwt.async_exception_hook :=
    fun exn -> log (Printf.sprintf "OCaml exception in Lwt.async: %s"
                      (Printexc.to_string exn))


let rec removeChildren el =
  Js.Opt.iter (el##lastChild)
    (fun c ->
      Dom.removeChild el c;
      removeChildren el)


}}

let lwt_or b th = if b then Lwt.return true else th
let lwt_and b th = if b then th else Lwt.return false

let base64url_of_base64 s =
  for i = 0 to String.length s - 1 do
    if s.[i] = '+' then s.[i] <- '-' ;
    if s.[i] = '/' then s.[i] <- '_' ;
  done

let send_mail ~from_addr ~to_addrs ~subject content =
  (* TODO with fork ou mieux en utilisant l'event loop de ocamlnet *)
  try_lwt
    Netsendmail.sendmail
      (Netsendmail.compose ~from_addr ~to_addrs ~subject content);
    Lwt.return true
  with _ -> (Eliom_lib.debug "SENDING INVITATION FAILED" ; Lwt.return false)

let send_invitation ?name ~email ~sponsor ~disctitle ~uri () =
  let name = match name with
    | None -> ""
    | Some n -> n
  in
  try_lwt
    ignore (Netaddress.parse email);
    send_mail
      ~from_addr:("Myproject Team", "noreply@ocsigenlabs.com")
      ~to_addrs:[(name, email)]
      ~subject:"Myproject invitation"
      (sponsor ^ "invited you to share a connective discussion on Myproject."
       ^ "\n"
       ^ "Title: " ^ disctitle
       ^ "\n"
       ^ "To activate your Myproject account, please visit the \
             following link:\n" ^ uri
       ^ "\n"
       ^ "This is an auto-generated message. "
       ^ "Please do not reply.\n")
  with _ -> (Eliom_lib.debug "SENDING INVITATION FAILED" ; Lwt.return false)
