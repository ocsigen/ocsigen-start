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

open Resource_pooling

let section = Logs.Src.create "os:db"
let ( >>= ) = fun x1 x2 -> x2 x1

module Lwt_thread = struct
  let close_in = fun x1 -> Eio.Resource.close x1

  let really_input
        (* TODO: ciao-lwt: [x2] should be a [Cstruct.t]. *)
        (* TODO: ciao-lwt: [Eio.Flow.single_read] operates on a [Flow.source] but [x1] is likely of type [Eio.Buf_read.t]. Rewrite this code to use [Buf_read] (which contains an internal buffer) or change the call to [Eio.Buf_read.of_flow] used to create the buffer. *)
        (* TODO: ciao-lwt: Dropped expression (buffer offset): [x3]. This will behave as if it was [0]. *)
        (* TODO: ciao-lwt: Dropped expression (buffer length): [x4]. This will behave as if it was [Cstruct.length buffer]. *)
    =
   fun x1 x2 x3 x4 -> Eio.Flow.read_exact x1 x2

  let input_binary_int = Lwt_io.BE.read_int
  let input_char = Lwt_io.read_char
  let output_string = fun x1 x2 -> Eio.Buf_write.string x1 x2
  let output_binary_int = Lwt_io.BE.write_int
  let output_char = Lwt_io.write_char
  let flush = fun x1 -> Eio.Buf_write.flush x1
  let open_connection x = Lwt_io.open_connection x

  type out_channel = Eio.Buf_write.t
  type in_channel = Eio.Buf_read.t
end

module Lwt_PGOCaml = PGOCaml_generic.Make (Lwt_thread)
module PGOCaml = Lwt_PGOCaml

let host_r = ref None
let port_r = ref None
let user_r = ref None
let password_r = ref None
let database_r = ref None
let unix_domain_socket_dir_r = ref None
let init_r = ref None
let dispose db = try PGOCaml.close db with _ -> ()

let connect () =
  let h =
    Lwt_PGOCaml.connect ?host:!host_r ?port:!port_r ?user:!user_r
      ?password:!password_r ?database:!database_r
      ?unix_domain_socket_dir:!unix_domain_socket_dir_r ()
  in
  match !init_r with
  | Some init ->
      let () =
        try init h
        with exn ->
          let () = dispose h in
          raise exn
      in
      h
  | None -> h

let validate db =
  try
    let () = Lwt_PGOCaml.ping db in
    true
  with _ -> false

let pool : (string, bool) Hashtbl.t Lwt_PGOCaml.t Resource_pool.t ref =
  ref @@ Resource_pool.create 16 ~validate ~dispose connect

let set_pool_size n = pool := Resource_pool.create n ~validate ~dispose connect

let init
      ?host
      ?port
      ?user
      ?password
      ?database
      ?unix_domain_socket_dir
      ?pool_size
      ?init
      ()
  =
  host_r := host;
  port_r := port;
  user_r := user;
  password_r := password;
  database_r := database;
  unix_domain_socket_dir_r := unix_domain_socket_dir;
  init_r := init;
  match pool_size with None -> () | Some n -> set_pool_size n

let connection_pool () = !pool

type wrapper = {f : 'a. PGOCaml.pa_pg_data PGOCaml.t -> (unit -> 'a) -> 'a}

let connection_wrapper = ref {f = (fun _ f -> f ())}
let set_connection_wrapper f = connection_wrapper := f

let use_pool f =
  Resource_pool.use !pool @@ fun db ->
  !connection_wrapper.f db @@ fun () ->
  try f db with
  | Lwt_PGOCaml.Error msg as e ->
      Logs.err ~src:section (fun fmt -> fmt "postgresql protocol error: %s" msg);
      let () = Lwt_PGOCaml.close db in
      raise e
  | (Unix.Unix_error _ | End_of_file) as e ->
      Logs.err ~src:section (fun fmt ->
        fmt ("unix error" ^^ "@\n%s") (Printexc.to_string e));
      let () = Lwt_PGOCaml.close db in
      raise e
  | Lwt.Canceled as e ->
      Logs.err ~src:section (fun fmt -> fmt "thread canceled");
      let () = PGOCaml.close db in
      raise e

let transaction_block db f =
  try
    Lwt_PGOCaml.begin_work db >>= fun _ ->
    let r = f () in
    let () = Lwt_PGOCaml.commit db in
    r
  with
  | (Lwt_PGOCaml.Error _ | Lwt.Canceled | Unix.Unix_error _ | End_of_file) as e
    ->
      raise
        (* The connection is going to be closed by [use_pool],
        so no need to try to rollback *)
        e
  | e ->
      let () =
        try Lwt_PGOCaml.rollback db
        with Lwt_PGOCaml.PostgreSQL_Error _ ->
          (* If the rollback fails, for instance due to a timeout,
           it seems better to close the connection. *)
          Logs.err ~src:section (fun fmt -> fmt "rollback failed");
          Lwt_PGOCaml.close db
      in
      raise e

let full_transaction_block f =
  use_pool (fun db -> transaction_block db (fun () -> f db))

let without_transaction = use_pool
