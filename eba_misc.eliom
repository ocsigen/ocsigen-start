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
