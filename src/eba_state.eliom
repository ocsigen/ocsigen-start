module Make(C : Eba_config.State)(App : Eba_sigs.App) = struct

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
      ~persistent:(App.app_name^"_website_state")
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
