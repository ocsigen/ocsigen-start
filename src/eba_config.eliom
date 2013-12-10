let doc_start = ()

module type Page = sig
  class type config = object
    method title : string
    method js : string list list
    method css : string list list
    method other_head : Eba_shared.Page.head_content

    method default_error_page :
      'a 'b. 'a -> 'b -> exn -> Eba_shared.Page.page_content Lwt.t
    method default_connected_error_page :
      'a 'b. int64 option -> 'a -> 'b -> exn -> Eba_shared.Page.page_content Lwt.t

    method default_predicate :
      'a 'b. 'a -> 'b -> bool Lwt.t
    method default_connected_predicate :
      'a 'b. int64 -> 'a -> 'b -> bool Lwt.t
  end

  val config : config
end

module type Session = sig
  class type config = object
    method on_request : unit Lwt.t
    method on_denied_request : int64 -> unit Lwt.t
    method on_connected_request : int64 -> unit Lwt.t
    method on_open_session : int64 -> unit Lwt.t
    method on_close_session : unit Lwt.t
    method on_start_process : unit Lwt.t
    method on_start_connected_process : int64 -> unit Lwt.t
  end

  val config : config
end

module type Email = sig
  class type config = object
    method from_addr : (string * string)
    method mailer : string
  end

  val config : config
end

module type State = sig
  type t

  val states : (t * string * string option) list
  val default : unit -> t
end
