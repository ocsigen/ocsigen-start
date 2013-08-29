module type T = sig
  type state_t = private [> Eba_types.state_t ] deriving (Json)
  type t deriving (Json)

  val name_of_state : state_t -> string
  val desc_of_state : state_t -> string
  val fun_of_state : state_t -> (unit, unit) Eliom_pervasives.server_function
  val descopt_of_state : state_t -> string option

  val set_website_state : state_t -> unit Lwt.t
  val get_website_state : unit -> state_t Lwt.t

  val all : unit -> (state_t list)
end

module Make(M : sig
  type t = private [> Eba_types.state_t ] deriving (Json)

  val states : (t * string * string option) list
  val app_name : string
end)
=
struct

  module MMap = Map.Make(struct type t = M.t let compare = compare end)

  let table
        : (  string
           * string option
           * (unit, unit) Eliom_pervasives.server_function
          ) MMap.t ref
        = ref MMap.empty

  type state_t = M.t deriving (Json)
  type t = (M.t * string * string option) deriving (Json)

  let name_of_state (st : state_t) =
    let (n,_,_) = (MMap.find st !table) in n

  let descopt_of_state (st : state_t) =
    let (_,d,_) = (MMap.find st !table) in d

  let fun_of_state (st : state_t) =
    let (_,_,f) = (MMap.find st !table) in f

  let desc_of_state (st : state_t) =
    match descopt_of_state st with
      | None -> "no description given"
      | Some d -> d

  let state : state_t Eliom_reference.eref =
    Eliom_reference.eref
      ~scope:Eliom_common.site_scope
      ~persistent:(M.app_name^"_website_state")
      `Normal

  let set_website_state (st : state_t) =
    Eliom_reference.set state st

  let get_website_state () : state_t Lwt.t =
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
      (M.states)
end
