(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
 *
 * Copyright (C) 2014
 *      Charly Chevalier
 *      Vincent Balat
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
open Printf

{shared{
  let email_pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+[.][A-Z]+$"
}}

let from_addr = ref ("team DEFAULT", "noreply@DEFAULT.DEFAULT")

let mailer = ref "/usr/bin/sendmail"

let set_from_addr s = from_addr := s
let set_mailer s = mailer := s
let get_mailer () = !mailer

exception Invalid_mailer of string

let email_pattern = email_pattern

let email_regexp =
  Str.regexp_case_fold email_pattern

let is_valid email =
  Str.string_match email_regexp email 0

let send ?(from_addr = !from_addr) ~to_addrs ~subject content =
  (* TODO with fork ou mieux en utilisant l'event loop de ocamlnet *)
  let echo = printf "%s\n" in
  let flush () = printf "%!" in
  try
    let content =
      if List.length content = 0
      then ""
      else (
        List.fold_left
          (fun s1 s2 -> s1^"\n"^s2)
          (List.hd content) (List.tl content))
    in
    let print_tuple (a,b) = printf " (%s,%s)\n" a b in
    echo "Sending e-mail:";
    echo "[from_addr]: "; print_tuple from_addr;
    echo "[to_addrs]: [";
    List.iter print_tuple to_addrs;
    echo "]";
    printf "[content]:\n%s\n" content;
    lwt () = Lwt_preemptive.detach
        (Netsendmail.sendmail ~mailer:!mailer)
        (Netsendmail.compose ~from_addr ~to_addrs ~subject content)
    in
    echo "[SUCCESS]: e-mail has been sent!";
    Lwt.return ()
  with Netchannels.Command_failure (Unix.WEXITED 127) ->
    echo "[FAIL]: e-mail has not been sent!";
    flush ();
    Lwt.fail (Invalid_mailer (!mailer^" not found"))


{client{
let email_pattern = email_pattern
let regexp_email =
  Regexp.regexp_with_flag email_pattern "i"

let is_valid email =
  match Regexp.string_match regexp_email email 0 with
  | None -> false
  | Some _ -> true
}}
