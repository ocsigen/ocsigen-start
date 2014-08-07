(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
 *
 * Copyright (C) 2014
 *      Charly Chevalier
 *      Vincent Balat
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

(* VVV
   I DON'T UNDERSTAND WHAT A "STATE" IS.
   IT IS NOT THE SAME NOTION AS STATE IN ELIOM.
   DO YOU HAVE EXAMPLE OF USE OF THIS?
   IS IT GENERIC ENOUGH TO REQUIRE A MODULE?
   --Vincent
*)

module Make(C : Eba_config.State)(App : Eliom_registration.ELIOM_APPL) = struct

  module MMap = Map.Make(struct type t = C.t let compare = compare end)

  let table
        : (  string
           * string option
           * (unit, unit) Eliom_pervasives.server_function
          ) MMap.t ref
        = ref MMap.empty

  type state = C.t
  type t = (state * string * string option)

  let name_of_state st =
    let (n,_,_) = (MMap.find st !table) in n

  let descopt_of_state st =
    let (_,d,_) = (MMap.find st !table) in d

  let fun_of_state st =
    let (_,_,f) = (MMap.find st !table) in f

  let desc_of_state st =
    match descopt_of_state st with
      | None -> "no description given"
      | Some d -> d

  let state : state Eliom_reference.eref =
    Eliom_reference.eref_from_fun
      ~scope:Eliom_common.site_scope
      ~persistent:(App.application_name^"_website_state")
      C.default

  let set_website_state st =
    Eliom_reference.set state st

  let get_website_state () =
    Eliom_reference.get state

  let all () =
    List.map (fst) (MMap.bindings !table)

  let _ =
    List.iter
      (fun (k,n,d) ->
         let f =
           server_function
             Json.t<unit>
             (fun () -> set_website_state k)
         in
         table := MMap.add k (n,d,f) !table)
      (C.states)
end
