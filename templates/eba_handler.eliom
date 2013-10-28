(*
let preregister_handler () email =
  let egroup = Eg.preregister in
  lwt is_in = Eg.in_egroup ~email ~egroup in
  match_lwt User.uid_of_mail email with
    | None ->
        if is_in
        then
          (R.Error.push (`User_already_preregistered email);
           Lwt.return ())
        else
          (R.Notice.push `Preregistered;
           Eg.add_email ~email ~egroup)
    | Some _ ->
        R.Error.push (`User_already_exists email);
        Lwt.return ()
*)

(*
let sign_up_handler () email =
  match_lwt User.uid_of_mail email with
    | None ->
        (*lwt () = Eg.remove_email ~egroup:Egroups.preregister ~email in*)
        lwt act_key = generate_new_key email () in
        lwt _ = User.create ~act_key ~email (User.empty ()) in
        Lwt.return ()
    | Some _ ->
        R.Error.push (`User_already_exists email);
        Lwt.return ()
*)

let lost_password_handler () email =
  (* SECURITY: no check here. *)
  match_lwt User.uid_of_email email with
    | None ->
        R.Error.push (`User_does_not_exist email);
        Lwt.return ()
    | Some uid ->
        Lwt.return ()
        (*
         lwt act_key = generate_new_key email () in
         User.attach_activationkey ~act_key uid
         *)

let set_password_handler userid () (pwd, pwd2) =
  (* SECURITY: We get the userid from session cookie,
     and change personal data for this user. No other check. *)
  if pwd <> pwd2
  then
    (R.Error.push (`Set_password_failed "password does not match");
     Lwt.return ())
  else (
    Lwt.return ())
    (*(User.set userid ~password:pwd ())*)

let set_personal_data_handler userid ()
    (((firstname, lastname), (pwd, pwd2)) as pd) =
  (* SECURITY: We get the userid from session cookie,
     and change personal data for this user. No other check. *)
  if firstname = "" || lastname = "" || pwd <> pwd2
  then
    (R.Error.push (`Wrong_personal_data pd);
     Lwt.return ())
  else
    Lwt.return ()
      (*
    (User.set
       userid
       ~firstname ~lastname
       ~password:pwd ())
       *)

let crop_handler userid gp pp =
  let dynup_handler =
    (* Will return a function which takes GET and POST parameters *)
    Ew_dyn_upload.handler
      ~dir:["avatars"]
      ~remove_on_timeout:true
      ~extensions:["png"; "jpg"]
      (fun dname fname ->
         let path = List.fold_left (fun a b -> a^"/"^b) "./static" dname in
         let path = path^"/"^fname in
         let img = Magick.read_image path in
         let w,h =
           Magick.get_image_width img,
           Magick.get_image_height img
         in
         let resize w h =
           Magick.Imper.resize
             img
             ~width:w
             ~height:h
             ~filter:Magick.Point
             ~blur:0.0
         in
         let ratio w h new_w =
           let iof,foi = int_of_float,float_of_int in
             iof ((foi h) /. (foi w) *. (foi new_w))
         in
         let normalize n max =
           n * 100 / max
         in
         let w_max,h_max = 700,500 in
         let () =
           if w > w_max || h > h_max
           then
             if (normalize w w_max) > (normalize h h_max)
             then resize w_max (ratio w h w_max)
             else resize (ratio h w h_max) h_max
         in
         let () = Magick.write_image img ~filename:path in
         Lwt.return ())
  in
  dynup_handler gp pp

(*
  module Admin = Eba_admin.Make(
  struct
    module User = User
    module State = State
    module Groups = Groups

    let get_users_from_completion_rpc =
      server_function
        Json.t<string>
        (Session.connect_wrapper_rpc
           (fun uid_connected pattern ->
              Lwt.return []))
              (*User.users_of_pattern pattern))*)

    (** this rpc function is used to change the rights of a user
      * in the admin page *)
    let get_groups_of_user_rpc =
      server_function
        Json.t<int64>
        (Session.connect_wrapper_rpc
           (fun uid_connected uid ->
              let group_of_user group =
                (*Eba_misc.log (Groups.name_of group);*)
                (* (t: group * boolean: the user belongs to this group) *)
                lwt in_group = Groups.in_group ~userid:uid ~group in
                Lwt.return (group, in_group)
              in
           (*
              lwt l = Groups.all () in
              lwt groups = Lwt_list.map_s (group_of_user) l in
            *)
              let groups = [] in
              (*List.iter (fun (a,b) -> Printf.printf "(%s, %b)" (Groups.name_of a) (b)) groups;*)
              Lwt.return groups))

    (** this rpc function is used to change the rights of a user
      * in the admin page *)
    let set_group_of_user_rpc =
      server_function
        Json.t<int64 * (bool * Eba_types.Groups.t)>
        (Session.connect_wrapper_rpc
           (fun uid_connected (uid, (set, group)) ->
              lwt () =
                if set
                then Groups.add_user ~userid:uid ~group
                else Groups.remove_user ~userid:uid ~group
              in
              Lwt.return ()))

    let get_preregistered_emails_rpc =
      server_function
        Json.t<int>
        (Session.connect_wrapper_rpc
           (fun _ n ->
              Lwt.return []))
              (*Egroups.get_emails_in ~egroup:Egroups.preregister ~n))*)

    let create_account_rpc =
      server_function
        Json.t<string>
        (Session.connect_wrapper_rpc
           (fun _ email ->
              (*lwt () = sign_up_handler () email in*)
              Lwt.return ()))

  end)

  module A = Admin
           *)

let _ =
    Eliom_registration.Action.register
      Eba_services.lost_password_service
      lost_password_handler;

    (*
    Eliom_registration.Action.register
      Eba_services.sign_up_service
      sign_up_handler;
     *)

    (*
    Eliom_registration.Action.register
      Eba_services.preregister_service
      preregister_handler;
     *)

    Eliom_registration.Action.register
      Eba_services.set_password_service
      (Session.connect_wrapper_function set_password_handler);

    Eliom_registration.Action.register
      Eba_services.set_personal_data_service
      (Session.connect_wrapper_function set_personal_data_handler);

    Ew_dyn_upload.register
      Eba_services.crop_service
      (Session.connect_wrapper_function crop_handler);

