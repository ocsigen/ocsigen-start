val doc_start : unit

(** This module defines all the config modules needed by the main
  * functors of EBA.
  * Generally you can
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

    (** [title] corresponds to the html tag <title>, it will be inserted on all
      * your pages.  *)
  val title : string

    (** [js] corresponds to your javascripts files to include into each pages,
      * it will automatically preprend the suffix "js/" as directory.  *)
  val js : string list list

    (** [css] (same as [js] but for style files), it will automatically prepend
      * the suffix "css/" as directory.  *)
  val css : string list list

    (** [other_head] is a list of custom elements to add in the head section,
      * it can be used to add "meta" elements, for example. *)
  val other_head : Eba_shared.Page.head_content

    (** [default_error_page] See NOTE (above) *)
  val default_error_page :
      'a -> 'b -> exn -> Eba_shared.Page.page_content Lwt.t

    (** [default_connected_error_page] See NOTE (above) *)
  val default_connected_error_page :
      int64 option -> 'a -> 'b -> exn -> Eba_shared.Page.page_content Lwt.t

    (** [default_predicate] See NOTE (above) *)
  val default_predicate :
      'a -> 'b -> bool Lwt.t

    (** [default_connected_error_page] See NOTE (above) *)
  val default_connected_predicate :
      int64 -> 'a -> 'b -> bool Lwt.t

end

(** The config module the module Session of EBA:
  *
  * You can define some hooks which will be called at specific moment
  * of a request:
  *
  * *)
module type Session = sig

    (** [on_request] is called during each requests *)
  val on_request : unit Lwt.t

    (** [on_denied_request] is called when a user can't access to a page
      * ([allows] and [deny] parameter of the connected [functions], see
      * module Page and Session for informations. *)
  val on_denied_request : int64 -> unit Lwt.t

    (** [on_connected_request] is called during each connected requests *)
  val on_connected_request : int64 -> unit Lwt.t

    (** [on_open_session] is called when a user connects *)
  val on_open_session : int64 -> unit Lwt.t

    (** [on_close_session] is called when a user disconnects *)
  val on_close_session : unit Lwt.t

    (** [on_start_process] is called when a new process is executed (a
      * process corresponds to a tab into your browser) *)
  val on_start_process : unit Lwt.t

    (** [on_start_connected_process] is the same as above, but it is only
      * called when a user is connected *)
  val on_start_connected_process : int64 -> unit Lwt.t

end

(** The config module the module Email of EBA:
  *
  * The Email module helps you to write easily your email. It uses [sendmail]
  * to send mail to someone.
  *
  *)
module type Email = sig

    (** [from_addr] is email address used to send mail *)
  val from_addr : (string * string)

    (** [mailer] corresponds to your binary [sendmail] on your system *)
  val mailer : string

end

module type State = sig
  type t

  val states : (t * string * string option) list
  val default : unit -> t
end
