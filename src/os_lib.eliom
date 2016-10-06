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

let%client reload () =
  Eliom_client.change_page ~service:Eliom_service.reload_action_hidden () ()

let%shared memoizator f =
  let value_ref = ref None in
  fun () ->
    match !value_ref with
    | Some value -> Lwt.return value
    | None ->
      let%lwt value = f () in
      value_ref := Some value;
      Lwt.return value

[%%server.start]
module Http =
  struct
    let string_of_stream ?(len=16384) contents =
      Lwt.try_bind
        (fun () ->
           Ocsigen_stream.string_of_stream len (Ocsigen_stream.get contents))
        (fun r ->
           let%lwt () = Ocsigen_stream.finalize contents `Success in
           Lwt.return r)
        (fun e ->
           let%lwt () = Ocsigen_stream.finalize contents `Failure in
           Lwt.fail e)
  end
