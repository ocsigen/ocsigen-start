(* Copyright Séverine Maingaud *)

{shared{

(* ************************** LIST *****************************  *)

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

}}
