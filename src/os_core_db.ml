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

let section = Logs.Src.create "os:db"
let ( >>= ) = fun x1 x2 -> x2 x1
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
    PGOCaml.connect ?host:!host_r ?port:!port_r ?user:!user_r
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
    let () = PGOCaml.ping db in
    true
  with _ -> false

let pool : (string, bool) Hashtbl.t PGOCaml.t Eio.Pool.t ref =
  ref @@ Eio.Pool.create 16 ~validate ~dispose connect

let set_pool_size n = pool := Eio.Pool.create n ~validate ~dispose connect

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
  Logs.warn ~src:section (fun fmt -> fmt "[use_pool] acquiring connection");
  Eio.Pool.use !pool @@ fun db ->
  Logs.warn ~src:section (fun fmt -> fmt "[use_pool] got connection");
  !connection_wrapper.f db @@ fun () ->
  try
    let r = f db in
    Logs.warn ~src:section (fun fmt -> fmt "[use_pool] f done, releasing connection");
    r
  with
  | PGOCaml.Error msg as e ->
      Logs.err ~src:section (fun fmt -> fmt "postgresql protocol error: %s" msg);
      let () = PGOCaml.close db in
      raise e
  | (Unix.Unix_error _ | End_of_file) as e ->
      Logs.err ~src:section (fun fmt ->
        fmt ("unix error" ^^ "@\n%s") (Printexc.to_string e));
      let () = PGOCaml.close db in
      raise e
  | Eio.Cancel.Cancelled _ as e ->
      Logs.err ~src:section (fun fmt -> fmt "fiber canceled");
      let () = PGOCaml.close db in
      raise e

let transaction_block db f =
  try
    PGOCaml.begin_work db >>= fun _ ->
    Logs.warn ~src:section (fun fmt -> fmt "[transaction_block] begin_work done");
    let r = f () in
    Logs.warn ~src:section (fun fmt -> fmt "[transaction_block] f() done, about to commit");
    let () = PGOCaml.commit db in
    Logs.warn ~src:section (fun fmt -> fmt "[transaction_block] commit done");
    r
  with
  | (PGOCaml.Error _ | Eio.Cancel.Cancelled _ | Unix.Unix_error _ | End_of_file) as e ->
      raise
        (* The connection is going to be closed by [use_pool],
        so no need to try to rollback *)
        e
  | e ->
      let () =
        try PGOCaml.rollback db
        with PGOCaml.PostgreSQL_Error _ ->
          (* If the rollback fails, for instance due to a timeout,
           it seems better to close the connection. *)
          Logs.err ~src:section (fun fmt -> fmt "rollback failed");
          PGOCaml.close db
      in
      raise e

let full_transaction_block f =
  use_pool (fun db -> transaction_block db (fun () -> f db))

let without_transaction = use_pool
