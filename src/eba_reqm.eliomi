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

open Html5_types

exception No_value

(** The type of the html representation of request messages. *)
type html = div Eliom_content_core.Html5.elt

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
