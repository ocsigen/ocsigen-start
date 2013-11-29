module type App = sig
  include Eliom_registration.ELIOM_APPL

  val app_name : string
end

module type Groups = sig
  type t

  val in_group : group:t -> userid:int64 -> bool Lwt.t
end

(** Session module : TODO *)
module type Session = sig
  (** A type which represents a group. A user can belongs to a group or not.
    * You have to provide an interface of your group representation. *)
  type group

  exception Permission_denied
  exception Not_connected

  (** Explicitly connect the user. (on both side) *)
  val connect : int64 -> unit Lwt.t

  (** Explicitly disconnect the connected user (it takes no parameter because
    * EBA cache connection information for the current user). *)
  val disconnect : unit -> unit Lwt.t

  (** Wrap a function which take get and post paramters and the uid
    * of the user as first parameter and call it only if the user is
    * connected, otherwise it raise Not_connected. *)
  val connected_fun :
     ?allow:group list
  -> ?deny:group list
  -> (int64 -> 'a -> 'b -> 'c Lwt.t)
  -> 'a -> 'b
  -> 'c Lwt.t

  (** Same as [connect_wrapper_function] but only takes two parameters,
    * the uid and post parameters. You should use this wrapper for your
    * rpc ([Eliom_pervasives.server_function]). *)
  val connected_rpc :
     ?allow:group list
  -> ?deny:group list
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
       ?allow:group list
    -> ?deny:group list
    -> (int64 option -> 'a -> 'b -> 'c Lwt.t)
    -> 'a -> 'b
    -> 'c Lwt.t

    (** Same as [connected_wrapper] but the first parameter is wrapped into
      * an option and None represents a non-connected user. *)
    val connected_rpc :
       ?allow:group list
    -> ?deny:group list
    -> (int64 option -> 'a -> 'b Lwt.t)
    -> 'a
    -> 'b Lwt.t

    (** When connected, you can retrieve the current user id using this function.
      * If there is not user connected, the function will return None. *)
    val get_current_userid : unit -> int64 option
  end
end


(** Page module : TODO *)
module type Page = sig
  (** Module doc *)

  module Session : Session

  exception Predicate_failed of (exn option)
  exception Permission_denied
  exception Not_connected

  type page = [ Html5_types.html ] Eliom_content.Html5.elt
  type page_content = [ Html5_types.body_content ] Eliom_content.Html5.elt list

  (** Generate a page visible for non-connected and connected user.
    * Use the [predicate] function if you have something to check
    * before the generation of the page. Note that, if you return
    * [false], the page will be generated using the [fallback]
    * function. *)
  val page :    ?predicate:('a -> 'b -> bool Lwt.t)
             -> ?fallback:('a -> 'b -> exn -> page_content Lwt.t)
             -> ('a -> 'b -> page_content Lwt.t)
             -> 'a -> 'b
             -> page Lwt.t

  (** Generate a page only visible for connected user.
    * The arguments [allow] and [deny] represents groups to which
    * the user has belongs to them or not. If the user does not
    * respect these requirements, the [fallback] function will be
    * used.
    * The predicate has the same behaviour that the [page] one. *)
  val connected_page :    ?allow:Session.group list
                       -> ?deny:Session.group list
                       -> ?predicate:(int64 -> 'a -> 'b -> bool Lwt.t)
                       -> ?fallback:(int64 -> 'a -> 'b -> exn -> page_content Lwt.t)
                       -> (int64 -> 'a -> 'b -> page_content Lwt.t)
                       -> 'a -> 'b
                       -> page Lwt.t
end

(** Email module : TODO *)
module type Email = sig
  exception Invalid_mailer of string

  val email_pattern : string
  val is_valid : string -> bool
  val send :    ?from_addr:(string * string)
             -> to_addrs:((string * string) list)
             -> subject:string
             -> string list
             -> unit
end

(** This module attemps to follow the same design of the flash messages in
  * RoR.
  *
  * A request message lives only once during a request. Each new request
  * will clear the value of a request message.
  *
  * You could use request messages in case of submitted forms. To report
  * potentially errors, or just to notice the user that is accound has
  * been created.
  *
  * You can also use request message to pass value between the different
  * parts of your request.
  * *)
module type Reqm = sig
  (** The type of the html representation of request messages. *)
  type html = Html5_types.div Eliom_content_core.Html5.elt

  (** The type of a basic request message. *)
  class type virtual reqm_base = object
    method virtual to_html : html
  end

  (** The type of a request message. *)
  class type ['a] reqm = object
    inherit reqm_base

    method set : 'a -> unit
    method clear : unit
    method has : bool
    method get : 'a
    method get_opt : 'a option
    method to_html : html
  end

  (** The type of a [set] of {b request messages}. [set] can be used to store
    * any kind of {b request messages}. Once they are stored, you can get them
    * in readonly mode ([reqm_base] instance). *)
  type set

  (** Use these helpers to enforce the type of your request message on creation. *)
  type 'a cons
  val cons : 'a cons

  (** Create a new set. *)
  val create_set : string -> set

  (** Create a new request message. You can use [cons] label to enforce the type
    * of the request message.
    *
    * The functions [to_html] will be used in the readonly
    * represetation of your request message. The value of type ['a] will be
    * passed as parameter to these functions.
    * *)
  val create :
       ?cons:'a cons
    -> ?set:set
    -> ?default:(unit -> 'a)
    -> to_html:('a -> html)
    -> unit
    -> 'a reqm

  (** Returns the html representation of the request message. *)
  val to_html : #reqm_base -> html

  (** Set a value for the given request message. *)
  val set : 'a reqm -> 'a -> unit
  (** Helper to push an element into a list. *)
  val push : 'a list reqm -> 'a -> unit
  (** Get the value of a request message. May raise [No_value] if no value has
    * been sefwakor the request message. You can use the function [has] to know
    * if there is a value associated to the request message. *)
  val get : 'a reqm -> 'a
  (** Get the value of a request message using ['a option] type. *)
  val get_opt : 'a reqm -> 'a option
  (** Returns [true] if a value has been set for the request message. *)
  val has : 'a reqm -> bool
  (** Clear the value of a request message. Ignored in case of unset value. *)
  val clear : 'a reqm -> unit

  (** Get the name of a set. *)
  val name_of_set : set -> string
  (** Get all the request messages {b with a value} which belongs to
    * the given [set]. *)
  val to_list : set -> reqm_base list
end

module type State = sig
  type state
  type t = (state * string * string option)

  val name_of_state : state -> string
  val desc_of_state : state -> string
  val fun_of_state : state -> (unit, unit) Eliom_pervasives.server_function
  val descopt_of_state : state -> string option

  val set_website_state : state -> unit Lwt.t
  val get_website_state : unit -> state Lwt.t

  val all : unit -> (state list)
end

module Tools : sig
  module type Cache_f = sig
    module Make : functor
      (M : sig
         type key_t
         type value_t

         val compare : key_t -> key_t -> int
         val get : key_t -> value_t Lwt.t
       end) -> sig
      type key_t
      type value_t

      val has : key_t -> bool
      val set : key_t -> value_t -> unit

      val reset : key_t -> unit
      val get : key_t -> value_t Lwt.t
      val wrap_function : key_t -> (unit -> 'a Lwt.t) -> 'a Lwt.t
    end
  end
end

module type Tools = sig
  module Cache_f : Tools.Cache_f
end
