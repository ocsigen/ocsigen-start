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

module Make(C : Eba_config.Email) = struct
  exception Invalid_mailer of string

  include Eba_shared.Email

  let email_regexp =
    Str.regexp_case_fold email_pattern

  let is_valid email =
    Str.string_match email_regexp email 0

  let send ?(from_addr = C.from_addr) ~to_addrs ~subject content =
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
      Netsendmail.sendmail ~mailer:C.mailer
        (Netsendmail.compose ~from_addr ~to_addrs ~subject content);
      echo "[SUCCESS]: e-mail has been sent!"
    with Netchannels.Command_failure (Unix.WEXITED 127) ->
      echo "[FAIL]: e-mail has not been sent!";
      flush ();
      raise (Invalid_mailer (C.mailer^" not found"))
end
