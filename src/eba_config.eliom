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
let doc_start = ()

module type Page = sig
  val title : string
  val js : string list list
  val css : string list list
  val other_head : Eba_shared.Page.head_content

  val default_error_page :
      'a -> 'b -> exn -> Eba_shared.Page.page_content Lwt.t
  val default_connected_error_page :
      int64 option -> 'a -> 'b -> exn -> Eba_shared.Page.page_content Lwt.t

  val default_predicate :
      'a -> 'b -> bool Lwt.t
  val default_connected_predicate :
      int64 option -> 'a -> 'b -> bool Lwt.t
end

module type Session = sig
  val on_request : unit Lwt.t
  val on_denied_request : int64 -> unit Lwt.t
  val on_connected_request : int64 -> unit Lwt.t
  val on_open_session : int64 -> unit Lwt.t
  val on_close_session : unit Lwt.t
  val on_start_process : unit Lwt.t
  val on_start_connected_process : int64 -> unit Lwt.t
end

module type Email = sig
  val from_addr : (string * string)
  val mailer : string
end

module type State = sig
  type t

  val states : (t * string * string option) list
  val default : unit -> t
end
