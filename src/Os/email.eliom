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

open Lwt.Syntax

let log_section = Logs.Src.create "os:email"

let email_pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+[.][A-Z]+$"
let from_addr = ref ("team DEFAULT", "noreply@DEFAULT.DEFAULT")
let mailer = ref "sendmail"
let set_from_addr s = from_addr := s
let set_mailer s = mailer := s
let get_mailer () = !mailer

let email_pattern = email_pattern
let email_regexp = Str.regexp_case_fold email_pattern
let is_valid email = Str.string_match email_regexp email 0

(* Pipes an RFC-2822 message to a sendmail-compatible MTA. If the
   mailer is not on PATH, the email is logged to stderr instead so
   the application stays usable out of the box. Applications needing
   finer control (HTTP API, queue, etc.) can override via [set_send]. *)
let default_send ?url ~from_addr ~to_addrs ~subject content =
  let format_addr (name, email) =
    if name = "" then email else Printf.sprintf "\"%s\" <%s>" name email
  in
  let from_header = format_addr from_addr in
  let to_header = String.concat ", " (List.map format_addr to_addrs) in
  let body =
    let base = String.concat "\n" content in
    match url with None -> base | Some u -> base ^ u
  in
  let message =
    Printf.sprintf
      "From: %s\r\n\
       To: %s\r\n\
       Subject: %s\r\n\
       MIME-Version: 1.0\r\n\
       Content-Type: text/plain; charset=UTF-8\r\n\
       Content-Transfer-Encoding: 8bit\r\n\
       \r\n\
       %s\r\n"
      from_header to_header subject body
  in
  let dump_to_stderr () =
    Logs.warn ~src:log_section (fun fmt ->
      fmt
        "mailer %S not found; dumping email to stderr so the application \
         remains usable. Configure a sendmail-compatible MTA, or call \
         [Os.Email.set_mailer] / [Os.Email.set_send].@\n\
         ---8<--- begin email ---8<---@\n\
         %s\
         ---8<--- end email ---8<---"
        !mailer message)
  in
  Lwt.catch
    (fun () ->
       let cmd = "", [|!mailer; "-t"; "-i"|] in
       Lwt_process.with_process_out cmd (fun proc ->
         let* () = Lwt_io.write proc#stdin message in
         let* status = proc#close in
         match status with
         | Unix.WEXITED 0 -> Lwt.return_unit
         | Unix.WEXITED 127 -> dump_to_stderr (); Lwt.return_unit
         | _ ->
             let descr =
               match status with
               | Unix.WEXITED n -> Printf.sprintf "exited with code %d" n
               | Unix.WSIGNALED s -> Printf.sprintf "killed by signal %d" s
               | Unix.WSTOPPED s -> Printf.sprintf "stopped by signal %d" s
             in
             Logs.err ~src:log_section (fun fmt ->
               fmt "%s %s for %s" !mailer descr to_header);
             Lwt.return_unit))
    (function
      | Unix.Unix_error (Unix.ENOENT, _, _) ->
          dump_to_stderr (); Lwt.return_unit
      | exn ->
          Logs.err ~src:log_section (fun fmt ->
            fmt "send exception: %s" (Printexc.to_string exn));
          Lwt.return_unit)

let send_ref = ref default_send

let send ?url ?(from_addr = !from_addr) ~to_addrs ~subject content =
  !send_ref ?url ~from_addr ~to_addrs ~subject content

let set_send s = send_ref := s
