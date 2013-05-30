(* Copyright Vincent Balat, Séverine Maingaud *)

exception No_such_user

{shared{

type user = {userid: int64;
             username : string;
             useravatar : string option;
             new_user : bool;
             rights : int}
    deriving (Json)


(****************************** AVATAR FILES NAME ******************************)
let default_user_avatar = "__ol_default_user_avatar"
let mail_avatar = "__ol_default_mail_avatar"

(****************************** CSS CLASSES NAME *******************************)
let cls_avatar = "ol_avatar"
let cls_mail = "ol_avatar"
let cls_user = "ol_user"
let cls_users = "ol_users"
let cls_user_box = "ol_user_box"


(********************* TEST AND COMPARISON FUNCTIONS **************************)

let mem_user u0 u1 = (u0.userid = u1.userid)

let rec list_mem_user u0 = function
  | [] -> false
  | u1::l -> if mem_user u0 u1 then true else list_mem_user u0 l


(***************************** GET FUNCTIONS **********************************)

let name_of_user u = u.username
let avatar_of_user u = match u.useravatar with
  | None -> default_user_avatar
  | Some s -> s
let id_of_user u = u.userid


(*************************** FUNCTIONS ON AUTHOR ******************************)
open Eliom_content.Html5
open Eliom_content.Html5.F
let make_pic_uri p =
  (make_uri (Eliom_service.static_dir ()) ["avatars" ; p])
let make_pic_string_uri ?absolute p =
  (make_string_uri
     ?absolute ~service:(Eliom_service.static_dir ()) ["avatars" ; p])
let print_user_name u =
  span ~a:[a_class ["ol_username"]] [pcdata (name_of_user u)]
let print_user_avatar ?(cls=cls_avatar) u =
  img
    ~a:[a_class [cls]]
    ~alt:(name_of_user u)
    ~src:(make_pic_uri (avatar_of_user u))
    ()

let print_user ?(cls=cls_user_box) u =
  span ~a:[a_class [cls]]
    [print_user_avatar u ; print_user_name u]

let print_users ?(cls=cls_users) l =
  D.span ~a:[a_class [cls]] (List.map print_user l)
}}

(*************************** USER RIGHTS ******************************)
type user_rights_t =
  | User
  | Beta
  | Admin

let rights_value_to_user_rights = function
  | 0 -> User
  | 1 -> Beta
  | 2 -> Admin
  | _ -> failwith "invalid rights value"

let is_admin u =
  try
    match (rights_value_to_user_rights u.rights) with
      | Admin -> true
      | _ -> false
  with _ -> false

let is_beta u =
  try
    match (rights_value_to_user_rights u.rights) with
      | Beta -> true
      | _ -> false
  with _ -> false

let is_user u =
  try
    match (rights_value_to_user_rights u.rights) with
      | User -> true
      | _ -> false
  with _ -> false


(********************************* MISC ***************************************)
{server{
let create_user_from_db_info ?(default_avatar=default_user_avatar) u =
  let avatar = Sql.getn u#pic in
  let id = Sql.get u#userid in
  let fn = Sql.get u#firstname in
  let ln = Sql.get u#lastname in
  let r = Sql.get u#rights in
  let new_user = (fn = "") in
  let name = if new_user then ln else fn^" "^ln in
  {userid=id; username=name; useravatar=avatar; new_user; rights=r}

}}
