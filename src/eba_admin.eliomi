module type T = sig
  (** Generate the content of the admin page provided by EBA.
    * It is splitted into 3 different sections:
    * {1 website's state}
    * {2 preregister accounts}
    * {3 users settings}
    * *) (* TODO: add more content *)
  val admin_page_content : Eba_types.User.basic_t
  -> [Html5_types.body_content] Eliom_content.Html5.F.elt list Lwt.t
end

module Make : functor(M :
sig
  module User : Eba_user.T
  module State : Eba_state.T
  module Groups : Eba_groups.T

  val create_account_rpc
    : (string, unit)
    Eliom_pervasives.server_function

  val get_preregistered_emails_rpc
    : (int, string list)
    Eliom_pervasives.server_function

  val get_users_from_completion_rpc
    : (string, (Eba_types.User.basic_t list))
    Eliom_pervasives.server_function

  val get_groups_of_user_rpc
    : (int64, ((Eba_types.Groups.t * bool) list))
    Eliom_pervasives.server_function

  val set_group_of_user_rpc
    : (int64 * (bool * Eba_types.Groups.t), unit)
    Eliom_pervasives.server_function
end) -> T
