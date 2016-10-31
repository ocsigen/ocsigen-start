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

let%server action_link_key_created =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let%server wrong_pdata =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope
    (None : ((string * string) * (string * string)) option)

let%server wrong_password =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let%server account_not_activated =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let%server user_already_exists =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let%server user_does_not_exist =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let%server user_already_preregistered =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false

let%server action_link_key_outdated =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.request_scope false
