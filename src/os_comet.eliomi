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

[%%shared.start]
val __link : unit

type msg = Connection_changed | Heartbeat

[%%client.start]

val restart_process :
  unit ->
  unit

val handle_message : msg Lwt_stream.result -> unit Lwt.t

[%%server.start]

val create_monitor_channel :
  unit -> 'a Eliom_comet.Channel.t * ('a option -> unit)

val monitor_channel_ref :
  (msg Eliom_comet.Channel.t * (msg option -> unit)) option
  Eliom_reference.Volatile.eref

val already_send_ref : bool Eliom_reference.Volatile.eref
