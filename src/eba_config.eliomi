val doc_start : unit

(** This module defines all the config modules needed by the main
  * functor of EBA. Generally, each config module has a [config]
  * object. Sometimes types are required too. Generally you can
  * find a default version of each of these modules in [Eba_default].
  * *)

(** The config module the module Page of EBA:
  *
  * NOTE: All the functions prefixed by {b 'default_'} correspond to
  * default version of [predicate] and [fallback] functions of connected
  * and non-connected pages. Keep in mind that uses a specific [fallback]
  * or [predicate] for a page, will replace the default one.
  *
  * *)
module type Page = sig
  (** The config class *)
  class type config = object

    (** [title] corresponds to the html tag <title>, it will be inserted on all
      * your pages.  *)
    method title : string

    (** [js] corresponds to your javascripts files to include into each pages,
      * it will automatically preprend the suffix "js/" as directory.  *)
    method js : string list list

    (** [css] (same as [js] but for style files), it will automatically prepend
      * the suffix "css/" as directory.  *)
    method css : string list list

    (** [other_head] is a list of custom elements to add in the head section,
      * it can be used to add "meta" elements, for example. *)
    method other_head : Eba_shared.Page.head_content

    (** [default_error_page] See NOTE (above) *)
    method default_error_page :
      'a 'b. 'a -> 'b -> exn -> Eba_shared.Page.page_content Lwt.t

    (** [default_connected_error_page] See NOTE (above) *)
    method default_connected_error_page :
      'a 'b. int64 option -> 'a -> 'b -> exn -> Eba_shared.Page.page_content Lwt.t

    method default_denied_page :
      'a 'b. int64 option -> 'a -> 'b -> Eba_shared.Page.page_content Lwt.t

    (** [default_predicate] See NOTE (above) *)
    method default_predicate :
      'a 'b. 'a -> 'b -> bool Lwt.t

    (** [default_connected_error_page] See NOTE (above) *)
    method default_connected_predicate :
      'a 'b. int64 -> 'a -> 'b -> bool Lwt.t

  end

  (** The configuration class of the module. *)
  val config : config
end

(** The config module the module Session of EBA:
  *
  * You can define some hooks which will be called at specific moment
  * of a request:
  *
  * *)
module type Session = sig
  class type config = object
    (** The config class *)

    (** [on_request] is called during each requests *)
    method on_request : unit Lwt.t

    (** [on_denied_request] is called when a user can't access to a page
      * ([allows] and [deny] parameter of the connected [functions], see
      * module Page and Session for informations. *)
    method on_denied_request : int64 -> unit Lwt.t

    (** [on_connected_request] is called during each connected requests *)
    method on_connected_request : int64 -> unit Lwt.t

    (** [on_open_session] is called when a user connects *)
    method on_open_session : int64 -> unit Lwt.t

    (** [on_close_session] is called when a user disconnects *)
    method on_close_session : unit Lwt.t

    (** [on_start_process] is called when a new process is executed (a
      * process corresponds to a tab into your browser) *)
    method on_start_process : unit Lwt.t

    (** [on_start_connected_process] is the same as above, but it is only
      * called when a user is connected *)
    method on_start_connected_process : int64 -> unit Lwt.t
  end

  (** The configuration class of the module. *)
  val config : config
end

(** The config module the module Email of EBA:
  *
  * The Email module helps you to write easily your email. It uses [sendmail]
  * to send mail to someone.
  *
  *)
module type Email = sig
  (** The config class *)
  class type config = object

    (** [from_addr] is email address used to send mail *)
    method from_addr : (string * string)

    (** [mailer] corresponds to your binary [sendmail] on your system *)
    method mailer : string
  end

  (** The configuration class of the module. *)
  val config : config
end

module type State = sig
  type t

  val states : (t * string * string option) list
  val default : unit -> t
end
