(* Copyright Vincent Balat, Charly Chevalier *)

{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
}}

class type config = object
  method on_open_session : unit Lwt.t
  method on_close_session : unit Lwt.t
  method on_start_process : unit Lwt.t
  method on_start_connected_process : unit Lwt.t
end

module type T = sig
  (** Explicitly connect the user. (on both side) *)
  val connect : int64 -> unit Lwt.t

  (** Explicitly disconnect the connected user (it takes no parameter because
    * EBA cache connection information for the current user). *)
  val disconnect : unit -> unit Lwt.t

  (** Wrap a function which take get and post paramters and the uid
    * of the user as first parameter and call it only if the user is
    * connected, otherwise it raise Not_connected. *)
  val connected_fun :
     ?allow:Eba_types.Groups.t list
  -> ?deny:Eba_types.Groups.t list
  -> (int64 -> 'a -> 'b -> 'c Lwt.t)
  -> 'a -> 'b
  -> 'c Lwt.t

  (** Same as [connect_wrapper_function] but only takes two parameters,
    * the uid and post parameters. You should use this wrapper for your
    * rpc ([Eliom_pervasives.server_function]). *)
  val connected_rpc :
     ?allow:Eba_types.Groups.t list
  -> ?deny:Eba_types.Groups.t list
  -> (int64 -> 'a -> 'b Lwt.t)
  -> 'a
  -> 'b Lwt.t

  (** When connected, you can retrieve the current user id using this function.
    * If there is no user connected, the function raise Not_connected.  *)
  val get_current_userid : unit -> int64

  module Opt : sig
    (** Same as above but instead of raising an Not_connected, the first
      * parameter is wrapped into an option, None tells you that the user
      * is currently not connected. *)
    val connected_fun :
       ?allow:Eba_types.Groups.t list
    -> ?deny:Eba_types.Groups.t list
    -> (int64 option -> 'a -> 'b -> 'c Lwt.t)
    -> 'a -> 'b
    -> 'c Lwt.t

    (** Same as [connected_wrapper] but the first parameter is wrapped into
      * an option and None represents a non-connected user. *)
    val connected_rpc :
       ?allow:Eba_types.Groups.t list
    -> ?deny:Eba_types.Groups.t list
    -> (int64 option -> 'a -> 'b Lwt.t)
    -> 'a
    -> 'b Lwt.t

    (** When connected, you can retrieve the current user id using this function.
      * If there is not user connected, the function will return None. *)
    val get_current_userid : unit -> int64 option
  end

end

module Make : functor (M :
sig
  val config : config

  module Groups : Eba_groups.T
end) -> T
