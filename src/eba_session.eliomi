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
  (** Wrap a function which take get and post paramters and the uid
    * of the user as first parameter and call it only if the user is
    * connected, otherwise it raise Not_connected. *)
  val connect_wrapper_function :
     ?allow:Eba_types.Groups.t list
  -> ?deny:Eba_types.Groups.t list
  -> (int64 -> 'a -> 'b -> 'c Lwt.t)
  -> 'a -> 'b
  -> 'c Lwt.t

  (** Same as above but instead of raising an Not_connected, the first
    * parameter is wrapped into an option, None tells you that the user
    * is currently not connected. *)
  val anonymous_wrapper_function :
     ?allow:Eba_types.Groups.t list
  -> ?deny:Eba_types.Groups.t list
  -> (int64 option -> 'a -> 'b -> 'c Lwt.t)
  -> 'a -> 'b
  -> 'c Lwt.t

  (** Same as [connect_wrapper_function] but only takes two parameters,
    * the uid and post parameters. You should use this wrapper for your
    * rpc ([Eliom_pervasives.server_function]). *)
  val connect_wrapper_rpc :
     ?allow:Eba_types.Groups.t list
  -> ?deny:Eba_types.Groups.t list
  -> (int64 -> 'a -> 'b Lwt.t)
  -> 'a
  -> 'b Lwt.t

  (** Same as [connect_wrapper_rpc] but the first parameter is wrapped into
    * an option and None represents a non-connected user. *)
  val anonymous_wrapper_rpc :
     ?allow:Eba_types.Groups.t list
  -> ?deny:Eba_types.Groups.t list
  -> (int64 option -> 'a -> 'b Lwt.t)
  -> 'a
  -> 'b Lwt.t

  (** Explicitly connect the user. *)
  val connect : int64 -> unit Lwt.t

  (** Explicitly disconnect the connected user (it takes no parameter because
    * EBA cache connection information for the current user). *)
  val disconnect : unit -> unit Lwt.t
end

module Make : functor (M :
sig
  val config : config

  module Groups : Eba_groups.T
  module User : Eba_user.T
end) -> T
