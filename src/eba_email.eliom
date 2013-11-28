open Printf

class type config = object
  method from_addr : (string * string)
  method mailer : string
end

module type T = sig
  exception Invalid_mailer of string

  val email_pattern : string
  val is_valid : string -> bool
  val send :    ?from_addr:(string * string)
             -> to_addrs:((string * string) list)
             -> subject:string
             -> string list
             -> unit
end

module Make(M : sig val config : config end) = struct
  exception Invalid_mailer of string

  let email_pattern = Eba_config.Email.email_pattern

  let email_regexp =
    Str.regexp_case_fold email_pattern

  let is_valid email =
    Str.string_match email_regexp email 0

  let send ?(from_addr = M.config#from_addr) ~to_addrs ~subject content =
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
      Netsendmail.sendmail ~mailer:M.config#mailer
        (Netsendmail.compose ~from_addr ~to_addrs ~subject content);
      echo "[SUCCESS]: e-mail has been sent!"
    with Netchannels.Command_failure (Unix.WEXITED 127) ->
      echo "[FAIL]: e-mail has not been sent!";
      flush ();
      raise (Invalid_mailer (M.config#mailer^" not found"))
end
