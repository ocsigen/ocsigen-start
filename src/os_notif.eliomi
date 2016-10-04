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

(** Server to client notifications.

    This module makes possible for client side applications to be
    notified of changes on some indexed data on the server.

    Apply functor [Make] for each type of data you want to be able to listen on.
    Each client starts listening on one piece of data by calling function
    [listen] with the index of that piece of data as parameter.
    Client stops listening by calling function [unlisten],
    or when the client side state is closed (by timeout or when the user
    logs out for example).

    When the data is modified on server side, call function [notify]
    with the index of the data, and all clients listening to that piece
    of data will receive a notification. Function [notify] takes as parameter
    the function that will build a customize notification for each user.
    (Be careful to check that user has right to see this data at this moment).

    The functor will also create a client side react signal that will
    be updated every time the client is notified.
*)

(** we have two types of notifications ([server_notif], and [client_notif])
    because we might need to serialise and deserialise the notification twice.
    Once for broadcasting it to other servers (in case of a multi-server set-up)
    and once for transferring it to the client (after possibly transforming the
    message using information which is only disponible at the receiving server
    (see [prepare] below).
*)
module type S = sig

  type key
  type server_notif
  type client_notif

  (** Make client process listen on data whose index is [key] *)
  val listen : key -> unit

  (** Stop listening on data [key] *)
  val unlisten : key -> unit

  (** Make a user stop listening on data [key] *)
  val unlisten_user :
    ?sitedata:Eliom_common.sitedata -> userid:Os_user.id -> key -> unit

  (** Call [notify id] to send a notification to all clients currently
      listening on data [key].

      If [~notfor] is [`Me], notification will not be sent to the tab
      currently doing the request (the one which caused the notification to
      happen). If it is [`User id] it won't be sent to the user with id [id].
  *)
  (*TODO: is the restriction to the current tab relevant?*)
  val notify : ?notfor:[`Me | `User of Os_user.id] -> key -> server_notif -> unit

  (** Returns the client react event. Map a function on this event to react
      to notifications from the server.
      For example:
[{server{
  let _ = Os_session.on_start_process
    (fun () ->
       ignore {unit{ ignore (React.E.map handle_notif %(N.client_ev ())) }};
       Lwt.return ()
     )
}}
]

  *)
  val client_ev : unit -> (key * client_notif) Eliom_react.Down.t

end


module Make (A : sig
      type key
      type server_notif
      type client_notif
      (* [prepare] transforms server notifications into client notifications.
         It takes the userid as parameter, if a user is connected for this
         client process. If you do not want to send the notification for this
         user, for example because he is not allowed to see this data, make
         function [f] return [None].
      *)
      val prepare : int64 option -> server_notif -> client_notif option Lwt.t
    end) :
	S with type key = A.key
     and type server_notif = A.server_notif
     and type client_notif = A.client_notif

module Simple (A : sig
      type key
      type notification
    end) :
	S with type key = A.key
     and type server_notif = A.notification
     and type client_notif = A.notification
