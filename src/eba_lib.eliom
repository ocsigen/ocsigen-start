(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
 *
 * Copyright 2016 CNRS - Univ Paris Diderot - BeSport
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

[%%client
let reload () =
  Eliom_client.change_page ~service:Eliom_service.reload_action_hidden () ()
]

let%shared memoizator f =
  let value_ref = ref None in
  fun () ->
    match !value_ref with
    | Some value -> Lwt.return value
    | None ->
      let%lwt value = f () in
      value_ref := Some value;
      Lwt.return value

(**
 * base_and_path_of_url "http://ocsigen.org:80/tuto/manual" returns
 * (base, path) where base is "http://ocsigen.org:80" and path is
 * ["tuto", "manual"]
 *)
let base_and_path_of_url url =
  let (https, host, port, _, path, _, _) = Ocsigen_lib.Url.parse url in
  let https_str = match https with
  | None -> ""
  | Some x -> if x then "https://" else "http://"
  in
  let host_str = match host with
  | None -> ""
  | Some x -> x
  in
  let port_str = match port with
  | None -> ""
  | Some x -> string_of_int x
  in
  (https_str ^ host_str ^ ":" ^ port_str, path)


