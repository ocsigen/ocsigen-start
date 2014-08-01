let doc_start = ()

module type Page = sig
  val title : string
  val js : string list list
  val css : string list list
  val other_head : Eba_shared.Page.head_content

  val default_error_page :
      'a -> 'b -> exn -> Eba_shared.Page.page_content Lwt.t
  val default_connected_error_page :
      int64 option -> 'a -> 'b -> exn -> Eba_shared.Page.page_content Lwt.t

  val default_predicate :
      'a -> 'b -> bool Lwt.t
  val default_connected_predicate :
      int64 option -> 'a -> 'b -> bool Lwt.t
end

module type Session = sig
  val on_request : unit Lwt.t
  val on_denied_request : int64 -> unit Lwt.t
  val on_connected_request : int64 -> unit Lwt.t
  val on_open_session : int64 -> unit Lwt.t
  val on_close_session : unit Lwt.t
  val on_start_process : unit Lwt.t
  val on_start_connected_process : int64 -> unit Lwt.t
end

module type Email = sig
  val from_addr : (string * string)
  val mailer : string
end

module type State = sig
  type t

  val states : (t * string * string option) list
  val default : unit -> t
end
