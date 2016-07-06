(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
 *
 * Copyright (C) 2014
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

module type S = sig
  type key
  type notification
  val equal_key : key -> key -> bool
end

module Make(A : S) :
sig

  (** Make client process listen on data whose index is [key] *)
  val listen : A.key -> unit

  (** Stop listening on data [key] *)
  val unlisten : A.key -> unit

  (** Call [notify id f] to send a notification to all clients currently
      listening on data [key]. The notification is build using function [f],
      that takes the userid as parameter, if a user is connected for this
      client process.

      If you do not want to send the notification for this user,
      for example because he is not allowed to see this data,
      make function [f] return [None].

      If [~notforme] is [true], notification will not be sent to the tab
      currently doing the request (the one which caused the notification to
      happen). Default is [false].
  *)
  val notify : ?notforme:bool -> A.key ->
    (int64 option -> A.notification option Lwt.t) -> unit

  (** Returns the client react event. Map a function on this event to react
      to notifications from the server.
      For example:

      let%client handle_notification some_stuff ev =
         ...

      let%server something some_stuff =
         ignore
           [%client
              (ignore (React.E.map
		        (handle_notification ~%some_stuff)
		        ~%(Notif_module.client_ev ())
	      ) : unit)
           ]

  *)

  val client_ev : unit -> (A.key * A.notification) Eliom_react.Down.t

end
