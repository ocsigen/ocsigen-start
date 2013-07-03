(* Copyright Séverine Maingaud *)

{shared{

open Eliom_content
open Eliom_content.Html5
open Eliom_content.Html5.F
}}

{server{
  module M = Netstring_pcre
}}

{client{
  module M = Regexp
}}

{shared{
  let mail_regexp = M.regexp "[-_\\.a-zA-Z0-9]+@[a-zA-Z0-9]+[-_\\.a-zA-Z0-9]*"
}}


{shared{
module type BaseTypes =
  sig
    type member deriving (Json)
    val cls_avatar: string
    val cls_mail: string
    val cls_mailbox: string
    val cls_members: string
    val cls_member_input: string
    val cls_member_selector: string
    val class_of_member: member -> string
    val class_of_memberbox: member -> string
    val mail_avatar: string
    val avatar_of_member: member -> string
    val name_of_member: member -> string
    val id_of_member: member -> int64
    val mem_member: member -> member -> bool
    val get_memberlist: (Text.t, member list) Eliom_pervasives.server_function
    val newmember_from_mail: string -> member Lwt.t
  end
}}


{shared{
module type BaseWidgets =
  sig
    include BaseTypes
    type mail = string deriving (Json)
    type t = Invited of mail | Member of member  deriving (Json)
    val name_of: t -> string
    val avatar_of: t -> string
    val class_of: t -> string
    val class_of_tbox: t -> string
    val cls_ts: string
    val might_be_mail: string -> bool
    val is_valid_mail: string -> bool
    val of_mail: mail -> t
    val of_member: member -> t
    val mem: t -> t -> bool
    val filter: t list -> mail list * member list
    val remove_member: member -> member list -> member list
    val remove: t -> t list -> t list
    val union: t list -> t list
    val contains: t list -> t -> bool
    val print_member_name: member ->  [> Html5_types.span ] Eliom_content_core.Html5.elt
    val print_member_avatar: member -> [> `Img ] Eliom_content_core.Html5.elt
    val print_member: member ->  [> Html5_types.span ] Eliom_content_core.Html5.elt
    val print_members: member list ->  [> Html5_types.span ] Eliom_content_core.Html5.elt
    val print_name: t ->  [> Html5_types.span ] Eliom_content_core.Html5.elt
    val print_avatar: t ->  [> `Img | `Span ] Eliom_content_core.Html5.elt
    val print_one: t ->  [> Html5_types.span ] Eliom_content_core.Html5.elt
    val print_list: t list ->  [> Html5_types.span ] Eliom_content_core.Html5.elt
  end
}}

{shared{
module type MakeBaseWidgets =
  functor (BT:BaseTypes) -> (BaseWidgets with type member = BT.member)
}}

{shared{
module MakeBaseWidgets(BT: BaseTypes) =
struct
  include BT
  type mail = string deriving (Json)
  type t = Invited of mail | Member of member  deriving (Json)


(****************************** GET FUNCTIONS **********************************)
  let name_of = function
    | Invited m -> m
    | Member a -> name_of_member a

  let avatar_of = function
    | Invited _ -> mail_avatar
    | Member a -> avatar_of_member a

  let class_of = function
    | Invited _ -> cls_mail
    | Member a -> class_of_member a

  let class_of_tbox = function
    | Invited _ -> cls_mailbox
    | Member a -> class_of_memberbox a

  let cls_ts = cls_members


(*************************** FUNCTIONS ON MAILS ********************************)
let might_be_mail s = String.contains s '@'
let is_valid_mail s =
  match M.string_match mail_regexp s 0 with
    | None -> false
    | Some _ -> true


(************************** INJECTION FUNCTIONS *******************************)
  let of_mail m = Invited m
  let of_member a = Member a



(**************** FUNCTIONS ON TYPE MEMBER *******************)

  let contains_member = Ol_misc.List.contains mem_member

  let member_union = Ol_misc.List.union contains_member

  let remove_member = Ol_misc.List.remove mem_member



(**************** FUNCTIONS ON TYPE t *******************)

  let mem r0 r1 =
    match r0,r1 with
      | Invited m0, Invited m1 -> m0 = m1
      | Member a0, Member a1 -> mem_member a0 a1
      | _,_ -> false

  (* t list -> (invited list, member list)  *)
  let filter tlist =
    let rec aux (ml,al) = function
      | [] -> (ml,al)
      | Invited m :: l -> aux (m::ml,al) l
      | Member a :: l -> aux (ml,a::al) l
    in aux ([],[]) tlist


  let remove = Ol_misc.List.remove mem

  let contains = Ol_misc.List.contains mem

  let union = Ol_misc.List.union contains



(**************************** PRINT FUNCTIONS **********************************)
(*** MEMBERS ***)
  let print_member_name m =
    span ~a:[a_class [class_of_member m]] [pcdata (name_of_member m)]

  let print_member_avatar m =
      img
        ~a:[a_class [cls_avatar]]
        ~alt:(name_of_member m)
        ~src:(make_uri (Eliom_service.static_dir ())
                ["avatars" ; avatar_of_member m])
        ()

  let print_member m =
    span ~a:[a_class [class_of_memberbox m]]
      [print_member_avatar m ; print_member_name m]

  let print_members l = D.span ~a:[a_class [cls_members]]
    (List.map print_member l)



(*** RECIPIENTS ***)
  let print_name r =
    span ~a:[a_class [class_of r]] [pcdata (name_of r)]

  let print_avatar = function
    | Member a -> print_member_avatar a
    | Invited m -> span ~a:[a_class [cls_avatar]] [Icons.envelope]

  let print_one r =
    D.span ~a:[a_class [class_of_tbox r]]
      [print_avatar r ; print_name r]

  let print_list l =
    span ~a:[a_class [cls_ts]] (List.map print_one l)



(************************* CONVERSION FUNCTIONS ****************************)

  let create_members tlist =
    let rec aux acc = function
    | [] -> Lwt.return acc
    | r::l ->
      begin
        match r with
          | Member a -> aux (a::acc) l
          | Invited m -> lwt a = newmember_from_mail m in
                      aux (a::acc) l
      end
    in
    aux [] tlist

end
}}
