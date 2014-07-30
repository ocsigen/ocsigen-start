(*VVV

  MISSING HERE: AN EXPLANATION OF WHAT IS THIS MODULE
  I DON'T EVEN KNOW MYSELF ...
  -- Vincent

*)

let doc_start = ()

open Html5_types

exception No_value

type html = div Eliom_content.Html5.elt

class virtual reqm_base () = object
  method virtual to_html : html
end

class set name = object(self)

  val name : string = name
  val reqms' : (reqm_base list) Eliom_reference.Volatile.eref =
    (Eliom_reference.Volatile.eref
       ~scope:Eliom_common.request_scope [])

  method get_name = name

  method actives = Eliom_reference.Volatile.get reqms'

  method is_active (reqm : reqm_base) =
    try
      ignore (List.find ((=) reqm) (Eliom_reference.Volatile.get reqms'));
      true
    with Not_found -> false

  method set_active reqm =
    (try
       let reqm' = List.find ((=) reqm) (Eliom_reference.Volatile.get reqms') in
       self # unset_active reqm'
     with Not_found -> ());
    Eliom_reference.Volatile.set reqms'
      (reqm::(Eliom_reference.Volatile.get reqms'))

  method unset_active reqm =
    try
      let reqm = List.find ((=) reqm) (Eliom_reference.Volatile.get reqms') in
      let rec aux rl = function
        | [] -> rl
        | hd::tl ->
            if hd = reqm
            then aux rl tl
            else aux (hd::rl) tl
      in
      Eliom_reference.Volatile.set reqms'
        (aux [] (Eliom_reference.Volatile.get reqms'))
    with Not_found -> ()
end

class ['a] reqm ?set ?default ~to_html name =
  let set_if_set_is_def self = function
    | None -> ()
    | Some set ->
        set # set_active self
  in
  let unset_if_set_is_def self = function
    | None -> ()
    | Some set ->
        set # unset_active self
  in
  let unsafe_get = function
    | None -> failwith ("should never happen")
    | Some v -> v
  in
object(self)
  inherit reqm_base name

  val mutable v' : ('a option) Eliom_reference.Volatile.eref option = None

  method set v =
    set_if_set_is_def (self :> reqm_base) set;
    Eliom_reference.Volatile.set (unsafe_get v') (Some v)

  method clear =
    unset_if_set_is_def (self :> reqm_base) set;
    Eliom_reference.Volatile.set (unsafe_get v') (None)

  method get_opt = Eliom_reference.Volatile.get (unsafe_get v')

  method has = not (self # get_opt = None)

  method get =
    match self # get_opt with
    | None -> raise No_value
    | Some v -> v

  method to_html =
    to_html (self # get)

  initializer
    v' <- Some (Eliom_reference.Volatile.eref
           ~scope:Eliom_common.request_scope None)
end

type 'a cons = unit
let cons = ()

let to_html reqm = reqm # to_html

let set reqm = reqm # set
let get reqm = reqm # get
let push reqm v = set reqm (v::(get reqm))
let get_opt reqm = reqm # get_opt

let has reqm = reqm # has
let clear reqm = reqm # clear

let name_of_set set = set # get_name
let to_list set = set # actives

let create_set name =
  new set name

let create
    ?(cons : 'a cons option)
    ?(set : set option)
    ?default
    ~to_html
    () : 'a reqm =
  let reqm = new reqm ?set ~to_html () in
  (match default with
   | None -> ()
   | Some default -> reqm # set (default ()));
  reqm
