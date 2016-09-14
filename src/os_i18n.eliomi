(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright (C) Université Paris Diderot, CNRS, INRIA, Be Sport.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

(** This module defines references to string for translations and for the use of
    i18n. It is is recommended to overwrite these variables when you use this
    library by using i18n.
    If you use the template provided with ocsigen-start, it is already done in
    PROJECT_NAME_i18n.

    These variables are mandatory in the library because it is used in
    {!Os_handlers}, {!Os_view} and {!Os_userbox}.
 *)

[%%shared.start]

module type I18NSIG = sig
  (** When two passwords do not match. *)
  val passwords_do_not_match                  : string

  (** The content of the email sent when an action key is generated. *)
  val generate_action_link_key_subject_email  : string

  (** The content of the email sent when an user signs up. *)
  val sign_up_email_msg                       : string

  (** When an email already exists. *)
  val email_already_exists                    : string

  (** When an user does not exist *)
  val user_does_not_exist                     : string

  (** When an account is not activated. *)
  val account_not_activated                   : string

  (** When a password is wrong. *)
  val wrong_password                          : string

  (** The content of the email sent when an email is added. *)
  val add_email_msg                           : string

  (** When an invalid action is used for a key. *)
  val invalid_action_key                      : string

  (** The content of the email sent when an user forgot his password. *)
  val forgot_pwd_email_msg                    : string

  (** When the user must be connected to see the current page. *)
  val must_be_connected_to_see_page           : string

  (** When an error occurs. *)
  val error                                   : string

  (** Text corresponding to ["email address"] *)
  val email_address                           : string

  (** Text corresponding to ["Your email"] *)
  val your_email                              : string

  (** Text corresponding to ["password"] *)
  val password                                : string

  (** Text corresponding to ["your password"] *)
  val your_password                           : string

  (** Text corresponding to ["retype password"] *)
  val retype_password                         : string

  (** Text corresponding to ["keep me logged in"] *)
  val keep_me_logged_in                       : string

  (** Text corresponding to ["sign in"] *)
  val sign_in                                 : string

  (** Text corresponding to ["logout"] *)
  val log_out                                 : string

  (** Text corresponding to ["your first name"] *)
  val your_first_name                         : string

  (** Text corresponding to ["your last name"] *)
  val your_last_name                          : string

  (** Text corresponding to ["submit"] *)
  val submit                                  : string

  (** Text corresponding to ["See help again from beginning"] *)
  val see_help_again_from_beginning           : string
end

module Current : sig
  (** When two passwords do not match. *)
  val passwords_do_not_match                  : unit -> string

  (** The content of the email sent when an action key is generated. *)
  val generate_action_link_key_subject_email  : unit -> string

  (** The content of the email sent when an user signs up. *)
  val sign_up_email_msg                       : unit -> string

  (** When an email already exists. *)
  val email_already_exists                    : unit -> string

  (** When an user does not exist *)
  val user_does_not_exist                     : unit -> string

  (** When an account is not activated. *)
  val account_not_activated                   : unit -> string

  (** When a password is wrong. *)
  val wrong_password                          : unit -> string

  (** The content of the email sent when an email is added. *)
  val add_email_msg                           : unit -> string

  (** When an invalid action is used for a key. *)
  val invalid_action_key                      : unit -> string

  (** The content of the email sent when an user forgot his password. *)
  val forgot_pwd_email_msg                    : unit -> string

  (** When the user must be connected to see the current page. *)
  val must_be_connected_to_see_page           : unit -> string

  (** When an error occurs. *)
  val error                                   : unit -> string

  (** Text corresponding to ["email address"] *)
  val email_address                           : unit -> string

  (** Text corresponding to ["Your email"] *)
  val your_email                              : unit -> string

  (** Text corresponding to ["password"] *)
  val password                                : unit -> string

  (** Text corresponding to ["your password"] *)
  val your_password                           : unit -> string

  (** Text corresponding to ["retype password"] *)
  val retype_password                         : unit -> string

  (** Text corresponding to ["keep me logged in"] *)
  val keep_me_logged_in                       : unit -> string

  (** Text corresponding to ["sign in"] *)
  val sign_in                                 : unit -> string

  (** Text corresponding to ["logout"] *)
  val log_out                                 : unit -> string

  (** Text corresponding to ["your first name"] *)
  val your_first_name                         : unit -> string

  (** Text corresponding to ["your last name"] *)
  val your_last_name                          : unit -> string

  (** Text corresponding to ["submit"] *)
  val submit                                  : unit -> string

  (** Text corresponding to ["See help again from beginning"] *)
  val see_help_again_from_beginning           : unit -> string
end

module Register (Language : I18NSIG) : sig end
