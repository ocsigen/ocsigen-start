(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright (C) Université Paris Diderot, CNRS, INRIA, Be Sport.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

let%client () = print_endline "[DEBUG] Os_email"

open Printf

let email_pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+[.][A-Z]+$"
let from_addr = ref ("team DEFAULT", "noreply@DEFAULT.DEFAULT")
let mailer = ref "sendmail"
let set_from_addr s = from_addr := s
let set_mailer s = mailer := s
let get_mailer () = !mailer

exception Invalid_mailer of string

let email_pattern = email_pattern
let email_regexp = Str.regexp_case_fold email_pattern
let is_valid email = Str.string_match email_regexp email 0

let default_send ?url:_ ~from_addr ~to_addrs ~subject:_ content =
  let echo = printf "%s\n" in
  let flush () = printf "%!" in
  let print_tuple (a, b) = printf " (%s,%s)\n" a b in
  let content =
    if List.length content = 0
    then ""
    else
      List.fold_left
        (fun s1 s2 -> s1 ^ "\n" ^ s2)
        (List.hd content) (List.tl content)
  in
  echo "Sending e-mail:";
  echo "[from_addr]: ";
  print_tuple from_addr;
  echo "[to_addrs]: [";
  List.iter print_tuple to_addrs;
  echo "]";
  printf "[content]:\n%s\n" content;
  echo "Please set your own sendmail function using Os_email.set_send";
  flush ()

let send_ref = ref default_send

let send ?url ?(from_addr = !from_addr) ~to_addrs ~subject content =
  !send_ref ?url ~from_addr ~to_addrs ~subject content

let set_send s = send_ref := s
