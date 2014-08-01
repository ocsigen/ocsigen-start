let doc_start = ()

module type Groups = sig
  type t

  val in_group : group:t -> userid:int64 -> bool Lwt.t
end

module type Session = sig
  type group

  exception Permission_denied
  exception Not_connected

  val connect : int64 -> unit Lwt.t
  val disconnect : unit -> unit Lwt.t

  val connected_fun :
     ?allow:group list
  -> ?deny:group list
  -> ?deny_fun:(int64 option -> 'c Lwt.t)
  -> (int64 -> 'a -> 'b -> 'c Lwt.t)
  -> 'a -> 'b
  -> 'c Lwt.t

  val connected_rpc :
     ?allow:group list
  -> ?deny:group list
  -> ?deny_fun:(int64 option -> 'b Lwt.t)
  -> (int64 -> 'a -> 'b Lwt.t)
  -> 'a
  -> 'b Lwt.t

  val get_current_userid : unit -> int64

  module Opt : sig
    val connected_fun :
       ?allow:group list
    -> ?deny:group list
    -> ?deny_fun:(int64 option -> 'c Lwt.t)
    -> (int64 option -> 'a -> 'b -> 'c Lwt.t)
    -> 'a -> 'b
    -> 'c Lwt.t

    val connected_rpc :
       ?allow:group list
    -> ?deny:group list
    -> ?deny_fun:(int64 option -> 'b Lwt.t)
    -> (int64 option -> 'a -> 'b Lwt.t)
    -> 'a
    -> 'b Lwt.t

    val get_current_userid : unit -> int64 option
  end
end

module type Page = sig
  module Session : Session

  exception Predicate_failed of (exn option)
  exception Permission_denied
  exception Not_connected

  type page = [ Html5_types.html ] Eliom_content.Html5.elt
  type page_content = [ Html5_types.body_content ] Eliom_content.Html5.elt list

  module Opt : sig
  (** The main function to generate pages for connected or non-connected user.
      The arguments [allow] and [deny] represents groups to which
      the user has to belongs or not. If the user does not
      respect these requirements, the [fallback] function will be
      used.
  *)
    val connected_page :
      ?allow:Session.group list
      -> ?deny:Session.group list
      -> ?predicate:(int64 option -> 'a -> 'b -> bool Lwt.t)
      -> ?fallback:(int64 option -> 'a -> 'b -> exn -> page_content Lwt.t)
      -> (int64 option -> 'a -> 'b -> page_content Lwt.t)
      -> 'a -> 'b
      -> page Lwt.t
  end

  val page :
       ?predicate:('a -> 'b -> bool Lwt.t)
    -> ?fallback:('a -> 'b -> exn -> page_content Lwt.t)
    -> ('a -> 'b -> page_content Lwt.t)
    -> 'a -> 'b
    -> page Lwt.t

  val connected_page :
       ?allow:Session.group list
    -> ?deny:Session.group list
    -> ?predicate:(int64 option -> 'a -> 'b -> bool Lwt.t)
    -> ?fallback:(int64 option -> 'a -> 'b -> exn -> page_content Lwt.t)
    -> (int64 -> 'a -> 'b -> page_content Lwt.t)
    -> 'a -> 'b
    -> page Lwt.t
end

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

module type Reqm = sig
  type html = Html5_types.div Eliom_content.Html5.elt

  class type virtual reqm_base = object
    method virtual to_html : html
  end

  class type ['a] reqm = object
    inherit reqm_base

    method set : 'a -> unit
    method clear : unit
    method has : bool
    method get : 'a
    method get_opt : 'a option
    method to_html : html
  end

  type set
  type 'a cons

  val cons : 'a cons

  val create_set : string -> set
  val create :
       ?cons:'a cons
    -> ?set:set
    -> ?default:(unit -> 'a)
    -> to_html:('a -> html)
    -> unit
    -> 'a reqm

  val to_html : #reqm_base -> html

  val set : 'a reqm -> 'a -> unit
  val push : 'a list reqm -> 'a -> unit
  val get : 'a reqm -> 'a
  val get_opt : 'a reqm -> 'a option
  val has : 'a reqm -> bool
  val clear : 'a reqm -> unit

  val name_of_set : set -> string
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

module Tools = struct
  module type Cache_sig = sig
    type key_t
    type value_t

    val has : key_t -> bool
    val set : key_t -> value_t -> unit

    val reset : key_t -> unit
    val get : key_t -> value_t Lwt.t
    val wrap_function : key_t -> (unit -> 'a Lwt.t) -> 'a Lwt.t
  end
  module type Cache_f = sig
    module Make : functor
      (M : sig
         type key_t
         type value_t

         val compare : key_t -> key_t -> int
         val get : key_t -> value_t Lwt.t
       end) -> Cache_sig with type key_t = M.key_t and type value_t = M.value_t
  end
end

module type Tools = sig
  module Cache_f : Tools.Cache_f
end
