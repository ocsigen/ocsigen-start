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

let%server passwords_do_not_match_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Passwords do not match"

let%server generate_action_link_key_subject_email_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "creation"

let%server sign_up_email_msg_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Welcome!\r\nTo confirm your e-mail address, \
       please click on this link: "

let%server email_already_exists_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "E-mail already exists"

let%server user_does_not_exist_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "user does not exist"

let%server account_not_activated_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Account not activated"

let%server wrong_password_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Wrong password"

let%server add_email_msg_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Welcome!\r\nTo confirm your e-mail address, \
       please click on this link: "

let%server invalid_action_key_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Invalid action key, please ask for a new one."

let%server forgot_pwd_email_msg_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Hi,\r\nTo set a new password, \
       please click on this link: "

let%server must_be_connected_to_see_page_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "You must be connected to see this page."

let%server error_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Error"

let%server email_address_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "E-mail address"

let%server your_email_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Your email"

let%server password_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Password"

let%server your_password_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Your password"

let%server retype_password_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Retype password"

let%server keep_me_logged_in_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "keep me logged in"

let%server sign_in_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Sign in"

let%server log_out_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Logout"

let%server your_first_name_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Your first name"

let%server your_last_name_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Your last name"

let%server submit_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "Submit"

let%server see_help_again_from_beginning_r =
 Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_process_scope "See help again from beginning"

let%client passwords_do_not_match_r =
  ref "Passwords do not match"

let%client generate_action_link_key_subject_email_r =
  ref "creation"

let%client sign_up_email_msg_r =
  ref "Welcome!\r\nTo confirm your e-mail address, \
       please click on this link: "

let%client email_already_exists_r =
  ref "E-mail already exists"

let%client user_does_not_exist_r =
  ref "user does not exist"

let%client account_not_activated_r =
  ref "Account not activated"

let%client wrong_password_r =
  ref "Wrong password"

let%client add_email_msg_r =
  ref "Welcome!\r\nTo confirm your e-mail address, \
       please click on this link: "

let%client invalid_action_key_r =
  ref "Invalid action key, please ask for a new one."

let%client forgot_pwd_email_msg_r =
  ref "Hi,\r\nTo set a new password, \
       please click on this link: "

let%client must_be_connected_to_see_page_r =
  ref "You must be connected to see this page."

let%client error_r =
  ref "Error"

let%client email_address_r =
  ref "E-mail address"

let%client your_email_r =
  ref "Your email"

let%client password_r =
  ref "Password"

let%client your_password_r =
  ref "Your password"

let%client retype_password_r =
  ref "Retype password"

let%client keep_me_logged_in_r =
  ref "keep me logged in"

let%client sign_in_r =
  ref "Sign in"

let%client log_out_r =
  ref "Logout"

let%client your_first_name_r =
  ref "Your first name"

let%client your_last_name_r =
  ref "Your last name"

let%client submit_r =
  ref "Submit"

let%client see_help_again_from_beginning_r =
  ref "See help again from beginning"

[%%shared
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
]

[%%server
  module Current = struct
    let passwords_do_not_match () =
     Eliom_reference.Volatile.get passwords_do_not_match_r

    let generate_action_link_key_subject_email () =
     Eliom_reference.Volatile.get generate_action_link_key_subject_email_r

    let sign_up_email_msg () =
     Eliom_reference.Volatile.get sign_up_email_msg_r

    let email_already_exists () =
     Eliom_reference.Volatile.get email_already_exists_r

    let user_does_not_exist () =
     Eliom_reference.Volatile.get user_does_not_exist_r

    let account_not_activated () =
     Eliom_reference.Volatile.get account_not_activated_r

    let wrong_password () =
     Eliom_reference.Volatile.get wrong_password_r

    let add_email_msg () =
     Eliom_reference.Volatile.get add_email_msg_r

    let invalid_action_key () =
     Eliom_reference.Volatile.get invalid_action_key_r

    let forgot_pwd_email_msg () =
     Eliom_reference.Volatile.get forgot_pwd_email_msg_r

    let must_be_connected_to_see_page () =
     Eliom_reference.Volatile.get must_be_connected_to_see_page_r

    let error () =
     Eliom_reference.Volatile.get error_r

    let email_address () =
     Eliom_reference.Volatile.get email_address_r

    let your_email () =
     Eliom_reference.Volatile.get your_email_r

    let password () =
     Eliom_reference.Volatile.get password_r

    let your_password () =
     Eliom_reference.Volatile.get your_password_r

    let retype_password () =
     Eliom_reference.Volatile.get retype_password_r

    let keep_me_logged_in () =
     Eliom_reference.Volatile.get keep_me_logged_in_r

    let sign_in () =
     Eliom_reference.Volatile.get sign_in_r

    let log_out () =
     Eliom_reference.Volatile.get log_out_r

    let your_first_name () =
     Eliom_reference.Volatile.get your_first_name_r

    let your_last_name () =
     Eliom_reference.Volatile.get your_last_name_r

    let submit () =
     Eliom_reference.Volatile.get submit_r

    let see_help_again_from_beginning () =
     Eliom_reference.Volatile.get see_help_again_from_beginning_r
  end
]

[%%client
  module Current = struct
    let passwords_do_not_match () =
     !passwords_do_not_match_r

    let generate_action_link_key_subject_email () =
     !generate_action_link_key_subject_email_r

    let sign_up_email_msg () =
     !sign_up_email_msg_r

    let email_already_exists () =
     !email_already_exists_r

    let user_does_not_exist () =
     !user_does_not_exist_r

    let account_not_activated () =
     !account_not_activated_r

    let wrong_password () =
     !wrong_password_r

    let add_email_msg () =
     !add_email_msg_r

    let invalid_action_key () =
     !invalid_action_key_r

    let forgot_pwd_email_msg () =
     !forgot_pwd_email_msg_r

    let must_be_connected_to_see_page () =
     !must_be_connected_to_see_page_r

    let error () =
     !error_r

    let email_address () =
     !email_address_r

    let your_email () =
     !your_email_r

    let password () =
     !password_r

    let your_password () =
     !your_password_r

    let retype_password () =
     !retype_password_r

    let keep_me_logged_in () =
     !keep_me_logged_in_r

    let sign_in () =
     !sign_in_r

    let log_out () =
     !log_out_r

    let your_first_name () =
     !your_first_name_r

    let your_last_name () =
     !your_last_name_r

    let submit () =
     !submit_r

    let see_help_again_from_beginning () =
     !see_help_again_from_beginning_r
  end
]

[%%server
  module Register (Language : I18NSIG) = struct
    Eliom_reference.Volatile.set
      passwords_do_not_match_r
      Language.passwords_do_not_match ;

    Eliom_reference.Volatile.set
      generate_action_link_key_subject_email_r
      Language.generate_action_link_key_subject_email ;

    Eliom_reference.Volatile.set
      sign_up_email_msg_r
      Language.sign_up_email_msg ;

    Eliom_reference.Volatile.set
      email_already_exists_r
      Language.email_already_exists ;

    Eliom_reference.Volatile.set
      user_does_not_exist_r
      Language.user_does_not_exist ;

    Eliom_reference.Volatile.set
      account_not_activated_r
      Language.account_not_activated ;

    Eliom_reference.Volatile.set
      wrong_password_r
      Language.wrong_password ;

    Eliom_reference.Volatile.set
      add_email_msg_r
      Language.add_email_msg ;

    Eliom_reference.Volatile.set
      invalid_action_key_r
      Language.invalid_action_key ;

    Eliom_reference.Volatile.set
      forgot_pwd_email_msg_r
      Language.forgot_pwd_email_msg ;

    Eliom_reference.Volatile.set
      must_be_connected_to_see_page_r
      Language.must_be_connected_to_see_page ;

    Eliom_reference.Volatile.set
      error_r
      Language.error ;

    Eliom_reference.Volatile.set
      email_address_r
      Language.email_address ;

    Eliom_reference.Volatile.set
      your_email_r
      Language.your_email ;

    Eliom_reference.Volatile.set
      password_r
      Language.password ;

    Eliom_reference.Volatile.set
      your_password_r
      Language.your_password ;

    Eliom_reference.Volatile.set
      retype_password_r
      Language.retype_password ;

    Eliom_reference.Volatile.set
      keep_me_logged_in_r
      Language.keep_me_logged_in ;

    Eliom_reference.Volatile.set
      sign_in_r
      Language.sign_in ;

    Eliom_reference.Volatile.set
      log_out_r
      Language.log_out ;

    Eliom_reference.Volatile.set
      your_first_name_r
      Language.your_first_name ;

    Eliom_reference.Volatile.set
      your_last_name_r
      Language.your_last_name ;

    Eliom_reference.Volatile.set
      submit_r
      Language.submit ;

    Eliom_reference.Volatile.set
      see_help_again_from_beginning_r
      Language.see_help_again_from_beginning ;
  end
]

[%%client
  module Register (Language : I18NSIG) = struct
    passwords_do_not_match_r := Language.passwords_do_not_match ;

    generate_action_link_key_subject_email_r := Language.generate_action_link_key_subject_email ;

    sign_up_email_msg_r := Language.sign_up_email_msg ;

    email_already_exists_r := Language.email_already_exists ;

    user_does_not_exist_r := Language.user_does_not_exist ;

    account_not_activated_r := Language.account_not_activated ;

    wrong_password_r := Language.wrong_password ;

    add_email_msg_r := Language.add_email_msg ;

    invalid_action_key_r := Language.invalid_action_key ;

    forgot_pwd_email_msg_r := Language.forgot_pwd_email_msg ;

    must_be_connected_to_see_page_r := Language.must_be_connected_to_see_page ;

    error_r := Language.error ;

    email_address_r := Language.email_address ;

    your_email_r := Language.your_email ;

    password_r := Language.password ;

    your_password_r := Language.your_password ;

    retype_password_r := Language.retype_password ;

    keep_me_logged_in_r := Language.keep_me_logged_in ;

    sign_in_r := Language.sign_in ;

    log_out_r := Language.log_out ;

    your_first_name_r := Language.your_first_name ;

    your_last_name_r := Language.your_last_name ;

    submit_r := Language.submit ;

    see_help_again_from_beginning_r := Language.see_help_again_from_beginning ;
  end
]
