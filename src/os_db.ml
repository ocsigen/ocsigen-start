(* GENERATED CODE, DO NOT EDIT! *)
include Os_core_db
exception No_such_resource 
exception Wrong_password 
exception Password_not_set 
exception No_such_user 
exception Empty_password 
exception Main_email_removal_attempt 
exception Account_not_activated 
let (>>=) = Lwt.bind
let one f ~success  ~fail  q =
  (f q) >>= (function | r::_ -> success r | _ -> fail)
let pwd_crypt_ref =
  ref
    ((fun password -> Bcrypt.string_of_hash (Bcrypt.hash password)),
      (fun _ ->
         fun password1 ->
           fun password2 ->
             Bcrypt.verify password1 (Bcrypt.hash_of_string password2)))
module Email =
  struct
    let available email =
      one full_transaction_block ~success:(fun _ -> Lwt.return_false)
        ~fail:Lwt.return_true
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_string)) email)]] in
              let split =
                [`Text
                   "SELECT 1\n             FROM ocsigen_start.emails\n             JOIN ocsigen_start.users USING (userid)\n             WHERE email = ";
                `Var ("email", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows ->
                PGOCaml.return
                  (let original_query =
                     "SELECT 1\n             FROM ocsigen_start.emails\n             JOIN ocsigen_start.users USING (userid)\n             WHERE email = $email" in
                   List.rev_map
                     (fun row ->
                        match row with
                        | c0::[] ->
                            PGOCaml_aux.Option.map
                              (let open PGOCaml in int32_of_string) c0
                        | _ ->
                            let msg =
                              "ppx_pgsql: internal error: " ^
                                ("Incorrect number of columns returned from query: "
                                   ^
                                   (original_query ^
                                      (".  Columns are: " ^
                                         (String.concat "; "
                                            (List.map
                                               (function
                                                | Some str ->
                                                    Printf.sprintf "%S" str
                                                | None -> "NULL") row))))) in
                            raise (PGOCaml.Error msg)) _rows)))
  end
module User =
  struct
    exception Invalid_action_link_key of Os_types.User.id 
    let userid_of_email email =
      one full_transaction_block ~success:(fun userid -> Lwt.return userid)
        ~fail:(Lwt.fail No_such_resource)
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_string)) email)]] in
              let split =
                [`Text
                   "SELECT userid\n           FROM ocsigen_start.users JOIN ocsigen_start.emails USING (userid)\n           WHERE email = ";
                `Var ("email", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows ->
                PGOCaml.return
                  (let original_query =
                     "SELECT userid\n           FROM ocsigen_start.users JOIN ocsigen_start.emails USING (userid)\n           WHERE email = $email" in
                   List.rev_map
                     (fun row ->
                        match row with
                        | c0::[] ->
                            (let open PGOCaml in int64_of_string)
                              (try PGOCaml_aux.Option.get c0
                               with
                               | _ ->
                                   failwith
                                     "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")
                        | _ ->
                            let msg =
                              "ppx_pgsql: internal error: " ^
                                ("Incorrect number of columns returned from query: "
                                   ^
                                   (original_query ^
                                      (".  Columns are: " ^
                                         (String.concat "; "
                                            (List.map
                                               (function
                                                | Some str ->
                                                    Printf.sprintf "%S" str
                                                | None -> "NULL") row))))) in
                            raise (PGOCaml.Error msg)) _rows)))
    let is_registered email =
      [%lwt
        try [%lwt let _ = userid_of_email email in Lwt.return_true]
        with | No_such_resource -> Lwt.return_false]
    let is_email_validated userid email =
      one full_transaction_block ~success:(fun _ -> Lwt.return_true)
        ~fail:Lwt.return_false
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_int64)) userid)];
                [Some (((let open PGOCaml in string_of_string)) email)]] in
              let split =
                [`Text
                   "SELECT 1 FROM ocsigen_start.emails\n           WHERE userid = ";
                `Var ("userid", false, false);
                `Text " AND email = ";
                `Var ("email", false, false);
                `Text " AND validated"] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows ->
                PGOCaml.return
                  (let original_query =
                     "SELECT 1 FROM ocsigen_start.emails\n           WHERE userid = $userid AND email = $email AND validated" in
                   List.rev_map
                     (fun row ->
                        match row with
                        | c0::[] ->
                            PGOCaml_aux.Option.map
                              (let open PGOCaml in int32_of_string) c0
                        | _ ->
                            let msg =
                              "ppx_pgsql: internal error: " ^
                                ("Incorrect number of columns returned from query: "
                                   ^
                                   (original_query ^
                                      (".  Columns are: " ^
                                         (String.concat "; "
                                            (List.map
                                               (function
                                                | Some str ->
                                                    Printf.sprintf "%S" str
                                                | None -> "NULL") row))))) in
                            raise (PGOCaml.Error msg)) _rows)))
    let set_email_validated userid email =
      full_transaction_block @@
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_int64)) userid)];
                [Some (((let open PGOCaml in string_of_string)) email)]] in
              let split =
                [`Text
                   "UPDATE ocsigen_start.emails SET validated = true\n         WHERE userid = ";
                `Var ("userid", false, false);
                `Text " AND email = ";
                `Var ("email", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows -> PGOCaml.return ()))
    let add_actionlinkkey ?(autoconnect= false)  ?(action=
      `AccountActivation)  ?(data= "")  ?(validity= 1L)  ~act_key  ~userid 
      ~email  () =
      let action =
        match action with
        | `AccountActivation -> "activation"
        | `PasswordReset -> "passwordreset"
        | `Custom s -> s in
      full_transaction_block @@
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_int64)) userid)];
                [Some (((let open PGOCaml in string_of_string)) email)];
                [Some (((let open PGOCaml in string_of_string)) action)];
                [Some (((let open PGOCaml in string_of_bool)) autoconnect)];
                [Some (((let open PGOCaml in string_of_string)) data)];
                [Some (((let open PGOCaml in string_of_int64)) validity)];
                [Some (((let open PGOCaml in string_of_string)) act_key)]] in
              let split =
                [`Text
                   "INSERT INTO ocsigen_start.activation\n           (userid, email, action, autoconnect, data,\n            validity, activationkey)\n         VALUES (";
                `Var ("userid", false, false);
                `Text ", ";
                `Var ("email", false, false);
                `Text ", ";
                `Var ("action", false, false);
                `Text ", ";
                `Var ("autoconnect", false, false);
                `Text ", ";
                `Var ("data", false, false);
                `Text ",\n                 ";
                `Var ("validity", false, false);
                `Text ", ";
                `Var ("act_key", false, false);
                `Text ")"] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows -> PGOCaml.return ()))
    let add_preregister email =
      full_transaction_block @@
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_string)) email)]] in
              let split =
                [`Text
                   "INSERT INTO ocsigen_start.preregister (email) VALUES (";
                `Var ("email", false, false);
                `Text ")"] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows -> PGOCaml.return ()))
    let remove_preregister email =
      full_transaction_block @@
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_string)) email)]] in
              let split =
                [`Text "DELETE FROM ocsigen_start.preregister WHERE email = ";
                `Var ("email", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows -> PGOCaml.return ()))
    let is_preregistered email =
      one full_transaction_block ~success:(fun _ -> Lwt.return_true)
        ~fail:Lwt.return_false
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_string)) email)]] in
              let split =
                [`Text
                   "SELECT 1 FROM ocsigen_start.preregister WHERE email = ";
                `Var ("email", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows ->
                PGOCaml.return
                  (let original_query =
                     "SELECT 1 FROM ocsigen_start.preregister WHERE email = $email" in
                   List.rev_map
                     (fun row ->
                        match row with
                        | c0::[] ->
                            PGOCaml_aux.Option.map
                              (let open PGOCaml in int32_of_string) c0
                        | _ ->
                            let msg =
                              "ppx_pgsql: internal error: " ^
                                ("Incorrect number of columns returned from query: "
                                   ^
                                   (original_query ^
                                      (".  Columns are: " ^
                                         (String.concat "; "
                                            (List.map
                                               (function
                                                | Some str ->
                                                    Printf.sprintf "%S" str
                                                | None -> "NULL") row))))) in
                            raise (PGOCaml.Error msg)) _rows)))
    let all ?(limit= 10L)  () =
      full_transaction_block @@
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_int64)) limit)]] in
              let split =
                [`Text "SELECT email FROM ocsigen_start.preregister LIMIT ";
                `Var ("limit", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows ->
                PGOCaml.return
                  (let original_query =
                     "SELECT email FROM ocsigen_start.preregister LIMIT $limit" in
                   List.rev_map
                     (fun row ->
                        match row with
                        | c0::[] ->
                            (let open PGOCaml in string_of_string)
                              (try PGOCaml_aux.Option.get c0
                               with
                               | _ ->
                                   failwith
                                     "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")
                        | _ ->
                            let msg =
                              "ppx_pgsql: internal error: " ^
                                ("Incorrect number of columns returned from query: "
                                   ^
                                   (original_query ^
                                      (".  Columns are: " ^
                                         (String.concat "; "
                                            (List.map
                                               (function
                                                | Some str ->
                                                    Printf.sprintf "%S" str
                                                | None -> "NULL") row))))) in
                            raise (PGOCaml.Error msg)) _rows)))
    let create ?password  ?avatar  ?language  ?email  ~firstname  ~lastname 
      () =
      if password = (Some "")
      then Lwt.fail_with "empty password"
      else
        full_transaction_block
          (fun dbh ->
             let password_o =
               Eliom_lib.Option.map (fun p -> fst (!pwd_crypt_ref) p)
                 password in
             [%lwt
               let userid =
                 [%lwt
                   match PGOCaml.bind
                           (let dbh = dbh in
                            let params : string option list list =
                              [[Some
                                  (((let open PGOCaml in string_of_string))
                                     firstname)];
                              [Some
                                 (((let open PGOCaml in string_of_string))
                                    lastname)];
                              [PGOCaml_aux.Option.map
                                 (let open PGOCaml in string_of_string) email];
                              [PGOCaml_aux.Option.map
                                 (let open PGOCaml in string_of_string)
                                 password_o];
                              [PGOCaml_aux.Option.map
                                 (let open PGOCaml in string_of_string)
                                 avatar];
                              [PGOCaml_aux.Option.map
                                 (let open PGOCaml in string_of_string)
                                 language]] in
                            let split =
                              [`Text
                                 "INSERT INTO ocsigen_start.users\n                   (firstname, lastname, main_email, password, avatar, language)\n                 VALUES (";
                              `Var ("firstname", false, false);
                              `Text ", ";
                              `Var ("lastname", false, false);
                              `Text ", ";
                              `Var ("email", false, true);
                              `Text ",\n                         ";
                              `Var ("password_o", false, true);
                              `Text ", ";
                              `Var ("avatar", false, true);
                              `Text ",  ";
                              `Var ("language", false, true);
                              `Text ")\n                 RETURNING userid"] in
                            let i = ref 0 in
                            let j = ref 0 in
                            let query =
                              String.concat ""
                                (List.map
                                   (function
                                    | `Text text -> text
                                    | `Var (_varname, false, _) ->
                                        let () = incr i in
                                        let () = incr j in
                                        "$" ^ (string_of_int j.contents)
                                    | `Var (_varname, true, _) ->
                                        let param =
                                          List.nth params i.contents in
                                        let () = incr i in
                                        "(" ^
                                          ((String.concat ","
                                              (List.map
                                                 (fun _ ->
                                                    let () = incr j in
                                                    "$" ^
                                                      (string_of_int
                                                         j.contents)) param))
                                             ^ ")")) split) in
                            let params = List.flatten params in
                            let name =
                              "ppx_pgsql." ^
                                (Digest.to_hex (Digest.string query)) in
                            let hash =
                              try PGOCaml.private_data dbh
                              with
                              | Not_found ->
                                  let hash = Hashtbl.create 17 in
                                  (PGOCaml.set_private_data dbh hash; hash) in
                            let is_prepared = Hashtbl.mem hash name in
                            PGOCaml.bind
                              (if not is_prepared
                               then
                                 PGOCaml.bind
                                   (PGOCaml.prepare dbh ~name ~query ())
                                   (fun () ->
                                      Hashtbl.add hash name true;
                                      PGOCaml.return ())
                               else PGOCaml.return ())
                              (fun () ->
                                 PGOCaml.execute_rev dbh ~name ~params ()))
                           (fun _rows ->
                              PGOCaml.return
                                (let original_query =
                                   "INSERT INTO ocsigen_start.users\n                   (firstname, lastname, main_email, password, avatar, language)\n                 VALUES ($firstname, $lastname, $?email,\n                         $?password_o, $?avatar,  $?language)\n                 RETURNING userid" in
                                 List.rev_map
                                   (fun row ->
                                      match row with
                                      | c0::[] ->
                                          (let open PGOCaml in
                                             int64_of_string)
                                            (try PGOCaml_aux.Option.get c0
                                             with
                                             | _ ->
                                                 failwith
                                                   "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")
                                      | _ ->
                                          let msg =
                                            "ppx_pgsql: internal error: " ^
                                              ("Incorrect number of columns returned from query: "
                                                 ^
                                                 (original_query ^
                                                    (".  Columns are: " ^
                                                       (String.concat "; "
                                                          (List.map
                                                             (function
                                                              | Some str ->
                                                                  Printf.sprintf
                                                                    "%S" str
                                                              | None ->
                                                                  "NULL") row))))) in
                                          raise (PGOCaml.Error msg)) _rows))
                   with
                   | userid::[] -> Lwt.return userid
                   | _ -> assert false] in
               [%lwt
                 let () =
                   match email with
                   | Some email ->
                       [%lwt
                         let () =
                           PGOCaml.bind
                             (let dbh = dbh in
                              let params : string option list list =
                                [[Some
                                    (((let open PGOCaml in string_of_string))
                                       email)];
                                [Some
                                   (((let open PGOCaml in string_of_int64))
                                      userid)]] in
                              let split =
                                [`Text
                                   "INSERT INTO ocsigen_start.emails (email, userid)\n                   VALUES (";
                                `Var ("email", false, false);
                                `Text ", ";
                                `Var ("userid", false, false);
                                `Text ")"] in
                              let i = ref 0 in
                              let j = ref 0 in
                              let query =
                                String.concat ""
                                  (List.map
                                     (function
                                      | `Text text -> text
                                      | `Var (_varname, false, _) ->
                                          let () = incr i in
                                          let () = incr j in
                                          "$" ^ (string_of_int j.contents)
                                      | `Var (_varname, true, _) ->
                                          let param =
                                            List.nth params i.contents in
                                          let () = incr i in
                                          "(" ^
                                            ((String.concat ","
                                                (List.map
                                                   (fun _ ->
                                                      let () = incr j in
                                                      "$" ^
                                                        (string_of_int
                                                           j.contents)) param))
                                               ^ ")")) split) in
                              let params = List.flatten params in
                              let name =
                                "ppx_pgsql." ^
                                  (Digest.to_hex (Digest.string query)) in
                              let hash =
                                try PGOCaml.private_data dbh
                                with
                                | Not_found ->
                                    let hash = Hashtbl.create 17 in
                                    (PGOCaml.set_private_data dbh hash; hash) in
                              let is_prepared = Hashtbl.mem hash name in
                              PGOCaml.bind
                                (if not is_prepared
                                 then
                                   PGOCaml.bind
                                     (PGOCaml.prepare dbh ~name ~query ())
                                     (fun () ->
                                        Hashtbl.add hash name true;
                                        PGOCaml.return ())
                                 else PGOCaml.return ())
                                (fun () ->
                                   PGOCaml.execute_rev dbh ~name ~params ()))
                             (fun _rows -> PGOCaml.return ()) in
                         remove_preregister email]
                   | None -> Lwt.return_unit in
                 Lwt.return userid]])
    let update ?password  ?avatar  ?language  ~firstname  ~lastname  userid =
      if password = (Some "")
      then Lwt.fail_with "empty password"
      else
        (let password =
           match password with
           | Some password -> Some (fst (!pwd_crypt_ref) password)
           | None -> None in
         full_transaction_block @@
           (fun dbh ->
              PGOCaml.bind
                (let dbh = dbh in
                 let params : string option list list =
                   [[Some
                       (((let open PGOCaml in string_of_string)) firstname)];
                   [Some (((let open PGOCaml in string_of_string)) lastname)];
                   [PGOCaml_aux.Option.map
                      (let open PGOCaml in string_of_string) password];
                   [PGOCaml_aux.Option.map
                      (let open PGOCaml in string_of_string) avatar];
                   [PGOCaml_aux.Option.map
                      (let open PGOCaml in string_of_string) language];
                   [Some (((let open PGOCaml in string_of_int64)) userid)]] in
                 let split =
                   [`Text
                      "UPDATE ocsigen_start.users\n           SET firstname = ";
                   `Var ("firstname", false, false);
                   `Text ",\n               lastname = ";
                   `Var ("lastname", false, false);
                   `Text ",\n               password = COALESCE(";
                   `Var ("password", false, true);
                   `Text ", password),\n               avatar = COALESCE(";
                   `Var ("avatar", false, true);
                   `Text ", avatar),\n               language = COALESCE(";
                   `Var ("language", false, true);
                   `Text ", language)\n           WHERE userid = ";
                   `Var ("userid", false, false)] in
                 let i = ref 0 in
                 let j = ref 0 in
                 let query =
                   String.concat ""
                     (List.map
                        (function
                         | `Text text -> text
                         | `Var (_varname, false, _) ->
                             let () = incr i in
                             let () = incr j in
                             "$" ^ (string_of_int j.contents)
                         | `Var (_varname, true, _) ->
                             let param = List.nth params i.contents in
                             let () = incr i in
                             "(" ^
                               ((String.concat ","
                                   (List.map
                                      (fun _ ->
                                         let () = incr j in
                                         "$" ^ (string_of_int j.contents))
                                      param))
                                  ^ ")")) split) in
                 let params = List.flatten params in
                 let name =
                   "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
                 let hash =
                   try PGOCaml.private_data dbh
                   with
                   | Not_found ->
                       let hash = Hashtbl.create 17 in
                       (PGOCaml.set_private_data dbh hash; hash) in
                 let is_prepared = Hashtbl.mem hash name in
                 PGOCaml.bind
                   (if not is_prepared
                    then
                      PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                        (fun () ->
                           Hashtbl.add hash name true; PGOCaml.return ())
                    else PGOCaml.return ())
                   (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
                (fun _rows -> PGOCaml.return ())))
    let update_password ~userid  ~password  =
      if password = ""
      then Lwt.fail_with "empty password"
      else
        (let password = fst (!pwd_crypt_ref) password in
         full_transaction_block @@
           (fun dbh ->
              PGOCaml.bind
                (let dbh = dbh in
                 let params : string option list list =
                   [[Some (((let open PGOCaml in string_of_string)) password)];
                   [Some (((let open PGOCaml in string_of_int64)) userid)]] in
                 let split =
                   [`Text "UPDATE ocsigen_start.users SET password = ";
                   `Var ("password", false, false);
                   `Text "\n           WHERE userid = ";
                   `Var ("userid", false, false)] in
                 let i = ref 0 in
                 let j = ref 0 in
                 let query =
                   String.concat ""
                     (List.map
                        (function
                         | `Text text -> text
                         | `Var (_varname, false, _) ->
                             let () = incr i in
                             let () = incr j in
                             "$" ^ (string_of_int j.contents)
                         | `Var (_varname, true, _) ->
                             let param = List.nth params i.contents in
                             let () = incr i in
                             "(" ^
                               ((String.concat ","
                                   (List.map
                                      (fun _ ->
                                         let () = incr j in
                                         "$" ^ (string_of_int j.contents))
                                      param))
                                  ^ ")")) split) in
                 let params = List.flatten params in
                 let name =
                   "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
                 let hash =
                   try PGOCaml.private_data dbh
                   with
                   | Not_found ->
                       let hash = Hashtbl.create 17 in
                       (PGOCaml.set_private_data dbh hash; hash) in
                 let is_prepared = Hashtbl.mem hash name in
                 PGOCaml.bind
                   (if not is_prepared
                    then
                      PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                        (fun () ->
                           Hashtbl.add hash name true; PGOCaml.return ())
                    else PGOCaml.return ())
                   (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
                (fun _rows -> PGOCaml.return ())))
    let update_avatar ~userid  ~avatar  =
      full_transaction_block @@
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_string)) avatar)];
                [Some (((let open PGOCaml in string_of_int64)) userid)]] in
              let split =
                [`Text "UPDATE ocsigen_start.users SET avatar = ";
                `Var ("avatar", false, false);
                `Text "\n         WHERE userid = ";
                `Var ("userid", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows -> PGOCaml.return ()))
    let update_main_email ~userid  ~email  =
      full_transaction_block @@
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_string)) email)];
                [Some (((let open PGOCaml in string_of_int64)) userid)]] in
              let split =
                [`Text
                   "UPDATE ocsigen_start.users u SET main_email = e.email\n         FROM ocsigen_start.emails e\n         WHERE e.email = ";
                `Var ("email", false, false);
                `Text " AND u.userid = ";
                `Var ("userid", false, false);
                `Text "\n           AND e.userid = u.userid AND e.validated"] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows -> PGOCaml.return ()))
    let update_language ~userid  ~language  =
      full_transaction_block @@
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_string)) language)];
                [Some (((let open PGOCaml in string_of_int64)) userid)]] in
              let split =
                [`Text "UPDATE ocsigen_start.users SET language = ";
                `Var ("language", false, false);
                `Text "\n         WHERE userid = ";
                `Var ("userid", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows -> PGOCaml.return ()))
    let verify_password ~email  ~password  =
      if password = ""
      then Lwt.fail Empty_password
      else
        one full_transaction_block
          (fun dbh ->
             PGOCaml.bind
               (let dbh = dbh in
                let params : string option list list =
                  [[Some (((let open PGOCaml in string_of_string)) email)]] in
                let split =
                  [`Text
                     "SELECT userid, password, validated\n               FROM ocsigen_start.users\n               JOIN ocsigen_start.emails USING (userid)\n               WHERE email = ";
                  `Var ("email", false, false)] in
                let i = ref 0 in
                let j = ref 0 in
                let query =
                  String.concat ""
                    (List.map
                       (function
                        | `Text text -> text
                        | `Var (_varname, false, _) ->
                            let () = incr i in
                            let () = incr j in
                            "$" ^ (string_of_int j.contents)
                        | `Var (_varname, true, _) ->
                            let param = List.nth params i.contents in
                            let () = incr i in
                            "(" ^
                              ((String.concat ","
                                  (List.map
                                     (fun _ ->
                                        let () = incr j in
                                        "$" ^ (string_of_int j.contents))
                                     param))
                                 ^ ")")) split) in
                let params = List.flatten params in
                let name =
                  "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
                let hash =
                  try PGOCaml.private_data dbh
                  with
                  | Not_found ->
                      let hash = Hashtbl.create 17 in
                      (PGOCaml.set_private_data dbh hash; hash) in
                let is_prepared = Hashtbl.mem hash name in
                PGOCaml.bind
                  (if not is_prepared
                   then
                     PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                       (fun () ->
                          Hashtbl.add hash name true; PGOCaml.return ())
                   else PGOCaml.return ())
                  (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
               (fun _rows ->
                  PGOCaml.return
                    (let original_query =
                       "SELECT userid, password, validated\n               FROM ocsigen_start.users\n               JOIN ocsigen_start.emails USING (userid)\n               WHERE email = $email" in
                     List.rev_map
                       (fun row ->
                          match row with
                          | c0::c1::c2::[] ->
                              (((let open PGOCaml in int64_of_string)
                                  (try PGOCaml_aux.Option.get c0
                                   with
                                   | _ ->
                                       failwith
                                         "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                                (PGOCaml_aux.Option.map
                                   (let open PGOCaml in string_of_string) c1),
                                ((let open PGOCaml in bool_of_string)
                                   (try PGOCaml_aux.Option.get c2
                                    with
                                    | _ ->
                                        failwith
                                          "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")))
                          | _ ->
                              let msg =
                                "ppx_pgsql: internal error: " ^
                                  ("Incorrect number of columns returned from query: "
                                     ^
                                     (original_query ^
                                        (".  Columns are: " ^
                                           (String.concat "; "
                                              (List.map
                                                 (function
                                                  | Some str ->
                                                      Printf.sprintf "%S" str
                                                  | None -> "NULL") row))))) in
                              raise (PGOCaml.Error msg)) _rows)))
          ~success:(fun (userid, password', validated) ->
                      match password' with
                      | Some password' when
                          snd (!pwd_crypt_ref) userid password password' ->
                          if validated
                          then Lwt.return userid
                          else Lwt.fail Account_not_activated
                      | Some _ -> Lwt.fail Wrong_password
                      | _ -> Lwt.fail Password_not_set)
          ~fail:(Lwt.fail No_such_user)
    let verify_password_phone ~number  ~password  =
      if password = ""
      then Lwt.fail Empty_password
      else
        one full_transaction_block
          (fun dbh ->
             PGOCaml.bind
               (let dbh = dbh in
                let params : string option list list =
                  [[Some (((let open PGOCaml in string_of_string)) number)]] in
                let split =
                  [`Text
                     "SELECT userid, password\n               FROM ocsigen_start.users\n               JOIN ocsigen_start.phones USING (userid)\n               WHERE number = ";
                  `Var ("number", false, false)] in
                let i = ref 0 in
                let j = ref 0 in
                let query =
                  String.concat ""
                    (List.map
                       (function
                        | `Text text -> text
                        | `Var (_varname, false, _) ->
                            let () = incr i in
                            let () = incr j in
                            "$" ^ (string_of_int j.contents)
                        | `Var (_varname, true, _) ->
                            let param = List.nth params i.contents in
                            let () = incr i in
                            "(" ^
                              ((String.concat ","
                                  (List.map
                                     (fun _ ->
                                        let () = incr j in
                                        "$" ^ (string_of_int j.contents))
                                     param))
                                 ^ ")")) split) in
                let params = List.flatten params in
                let name =
                  "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
                let hash =
                  try PGOCaml.private_data dbh
                  with
                  | Not_found ->
                      let hash = Hashtbl.create 17 in
                      (PGOCaml.set_private_data dbh hash; hash) in
                let is_prepared = Hashtbl.mem hash name in
                PGOCaml.bind
                  (if not is_prepared
                   then
                     PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                       (fun () ->
                          Hashtbl.add hash name true; PGOCaml.return ())
                   else PGOCaml.return ())
                  (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
               (fun _rows ->
                  PGOCaml.return
                    (let original_query =
                       "SELECT userid, password\n               FROM ocsigen_start.users\n               JOIN ocsigen_start.phones USING (userid)\n               WHERE number = $number" in
                     List.rev_map
                       (fun row ->
                          match row with
                          | c0::c1::[] ->
                              (((let open PGOCaml in int64_of_string)
                                  (try PGOCaml_aux.Option.get c0
                                   with
                                   | _ ->
                                       failwith
                                         "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                                (PGOCaml_aux.Option.map
                                   (let open PGOCaml in string_of_string) c1))
                          | _ ->
                              let msg =
                                "ppx_pgsql: internal error: " ^
                                  ("Incorrect number of columns returned from query: "
                                     ^
                                     (original_query ^
                                        (".  Columns are: " ^
                                           (String.concat "; "
                                              (List.map
                                                 (function
                                                  | Some str ->
                                                      Printf.sprintf "%S" str
                                                  | None -> "NULL") row))))) in
                              raise (PGOCaml.Error msg)) _rows)))
          ~success:(fun (userid, password') ->
                      match password' with
                      | Some password' when
                          snd (!pwd_crypt_ref) userid password password' ->
                          Lwt.return userid
                      | Some _ -> Lwt.fail Wrong_password
                      | _ -> Lwt.fail Password_not_set)
          ~fail:(Lwt.fail No_such_user)
    let user_of_userid userid =
      one full_transaction_block
        ~success:(fun
                    (userid, firstname, lastname, avatar, has_password,
                     language)
                    ->
                    Lwt.return
                      (userid, firstname, lastname, avatar,
                        (has_password = (Some true)), language))
        ~fail:(Lwt.fail No_such_resource)
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_int64)) userid)]] in
              let split =
                [`Text
                   "SELECT userid, firstname, lastname, avatar,\n                  password IS NOT NULL, language\n           FROM ocsigen_start.users WHERE userid = ";
                `Var ("userid", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows ->
                PGOCaml.return
                  (let original_query =
                     "SELECT userid, firstname, lastname, avatar,\n                  password IS NOT NULL, language\n           FROM ocsigen_start.users WHERE userid = $userid" in
                   List.rev_map
                     (fun row ->
                        match row with
                        | c0::c1::c2::c3::c4::c5::[] ->
                            (((let open PGOCaml in int64_of_string)
                                (try PGOCaml_aux.Option.get c0
                                 with
                                 | _ ->
                                     failwith
                                       "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                              ((let open PGOCaml in string_of_string)
                                 (try PGOCaml_aux.Option.get c1
                                  with
                                  | _ ->
                                      failwith
                                        "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                              ((let open PGOCaml in string_of_string)
                                 (try PGOCaml_aux.Option.get c2
                                  with
                                  | _ ->
                                      failwith
                                        "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                              (PGOCaml_aux.Option.map
                                 (let open PGOCaml in string_of_string) c3),
                              (PGOCaml_aux.Option.map
                                 (let open PGOCaml in bool_of_string) c4),
                              (PGOCaml_aux.Option.map
                                 (let open PGOCaml in string_of_string) c5))
                        | _ ->
                            let msg =
                              "ppx_pgsql: internal error: " ^
                                ("Incorrect number of columns returned from query: "
                                   ^
                                   (original_query ^
                                      (".  Columns are: " ^
                                         (String.concat "; "
                                            (List.map
                                               (function
                                                | Some str ->
                                                    Printf.sprintf "%S" str
                                                | None -> "NULL") row))))) in
                            raise (PGOCaml.Error msg)) _rows)))
    let get_actionlinkkey_info act_key =
      full_transaction_block
        (fun dbh ->
           one (fun q -> q dbh) ~fail:(Lwt.fail No_such_resource)
             (fun dbh ->
                PGOCaml.bind
                  (let dbh = dbh in
                   let params : string option list list =
                     [[Some
                         (((let open PGOCaml in string_of_string)) act_key)]] in
                   let split =
                     [`Text
                        "SELECT userid, email, validity, autoconnect, action, data\n               FROM ocsigen_start.activation\n               WHERE activationkey = ";
                     `Var ("act_key", false, false)] in
                   let i = ref 0 in
                   let j = ref 0 in
                   let query =
                     String.concat ""
                       (List.map
                          (function
                           | `Text text -> text
                           | `Var (_varname, false, _) ->
                               let () = incr i in
                               let () = incr j in
                               "$" ^ (string_of_int j.contents)
                           | `Var (_varname, true, _) ->
                               let param = List.nth params i.contents in
                               let () = incr i in
                               "(" ^
                                 ((String.concat ","
                                     (List.map
                                        (fun _ ->
                                           let () = incr j in
                                           "$" ^ (string_of_int j.contents))
                                        param))
                                    ^ ")")) split) in
                   let params = List.flatten params in
                   let name =
                     "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
                   let hash =
                     try PGOCaml.private_data dbh
                     with
                     | Not_found ->
                         let hash = Hashtbl.create 17 in
                         (PGOCaml.set_private_data dbh hash; hash) in
                   let is_prepared = Hashtbl.mem hash name in
                   PGOCaml.bind
                     (if not is_prepared
                      then
                        PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                          (fun () ->
                             Hashtbl.add hash name true; PGOCaml.return ())
                      else PGOCaml.return ())
                     (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
                  (fun _rows ->
                     PGOCaml.return
                       (let original_query =
                          "SELECT userid, email, validity, autoconnect, action, data\n               FROM ocsigen_start.activation\n               WHERE activationkey = $act_key" in
                        List.rev_map
                          (fun row ->
                             match row with
                             | c0::c1::c2::c3::c4::c5::[] ->
                                 (((let open PGOCaml in int64_of_string)
                                     (try PGOCaml_aux.Option.get c0
                                      with
                                      | _ ->
                                          failwith
                                            "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                                   ((let open PGOCaml in string_of_string)
                                      (try PGOCaml_aux.Option.get c1
                                       with
                                       | _ ->
                                           failwith
                                             "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                                   ((let open PGOCaml in int64_of_string)
                                      (try PGOCaml_aux.Option.get c2
                                       with
                                       | _ ->
                                           failwith
                                             "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                                   ((let open PGOCaml in bool_of_string)
                                      (try PGOCaml_aux.Option.get c3
                                       with
                                       | _ ->
                                           failwith
                                             "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                                   ((let open PGOCaml in string_of_string)
                                      (try PGOCaml_aux.Option.get c4
                                       with
                                       | _ ->
                                           failwith
                                             "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                                   ((let open PGOCaml in string_of_string)
                                      (try PGOCaml_aux.Option.get c5
                                       with
                                       | _ ->
                                           failwith
                                             "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")))
                             | _ ->
                                 let msg =
                                   "ppx_pgsql: internal error: " ^
                                     ("Incorrect number of columns returned from query: "
                                        ^
                                        (original_query ^
                                           (".  Columns are: " ^
                                              (String.concat "; "
                                                 (List.map
                                                    (function
                                                     | Some str ->
                                                         Printf.sprintf "%S"
                                                           str
                                                     | None -> "NULL") row))))) in
                                 raise (PGOCaml.Error msg)) _rows)))
             ~success:(fun
                         (userid, email, validity, autoconnect, action, data)
                         ->
                         let action =
                           match action with
                           | "activation" -> `AccountActivation
                           | "passwordreset" -> `PasswordReset
                           | c -> `Custom c in
                         let v = max 0L (Int64.pred validity) in
                         [%lwt
                           let () =
                             PGOCaml.bind
                               (let dbh = dbh in
                                let params : string option list list =
                                  [[Some
                                      (((let open PGOCaml in string_of_int64))
                                         v)];
                                  [Some
                                     (((let open PGOCaml in string_of_string))
                                        act_key)]] in
                                let split =
                                  [`Text
                                     "UPDATE ocsigen_start.activation\n                 SET validity = ";
                                  `Var ("v", false, false);
                                  `Text " WHERE activationkey = ";
                                  `Var ("act_key", false, false)] in
                                let i = ref 0 in
                                let j = ref 0 in
                                let query =
                                  String.concat ""
                                    (List.map
                                       (function
                                        | `Text text -> text
                                        | `Var (_varname, false, _) ->
                                            let () = incr i in
                                            let () = incr j in
                                            "$" ^ (string_of_int j.contents)
                                        | `Var (_varname, true, _) ->
                                            let param =
                                              List.nth params i.contents in
                                            let () = incr i in
                                            "(" ^
                                              ((String.concat ","
                                                  (List.map
                                                     (fun _ ->
                                                        let () = incr j in
                                                        "$" ^
                                                          (string_of_int
                                                             j.contents))
                                                     param))
                                                 ^ ")")) split) in
                                let params = List.flatten params in
                                let name =
                                  "ppx_pgsql." ^
                                    (Digest.to_hex (Digest.string query)) in
                                let hash =
                                  try PGOCaml.private_data dbh
                                  with
                                  | Not_found ->
                                      let hash = Hashtbl.create 17 in
                                      (PGOCaml.set_private_data dbh hash;
                                       hash) in
                                let is_prepared = Hashtbl.mem hash name in
                                PGOCaml.bind
                                  (if not is_prepared
                                   then
                                     PGOCaml.bind
                                       (PGOCaml.prepare dbh ~name ~query ())
                                       (fun () ->
                                          Hashtbl.add hash name true;
                                          PGOCaml.return ())
                                   else PGOCaml.return ())
                                  (fun () ->
                                     PGOCaml.execute_rev dbh ~name ~params ()))
                               (fun _rows -> PGOCaml.return ()) in
                           Lwt.return
                             (let open Os_types.Action_link_key in
                                {
                                  userid;
                                  email;
                                  validity;
                                  action;
                                  data;
                                  autoconnect
                                })]))
    let emails_of_userid userid =
      full_transaction_block @@
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_int64)) userid)]] in
              let split =
                [`Text
                   "SELECT email FROM ocsigen_start.emails WHERE userid = ";
                `Var ("userid", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows ->
                PGOCaml.return
                  (let original_query =
                     "SELECT email FROM ocsigen_start.emails WHERE userid = $userid" in
                   List.rev_map
                     (fun row ->
                        match row with
                        | c0::[] ->
                            (let open PGOCaml in string_of_string)
                              (try PGOCaml_aux.Option.get c0
                               with
                               | _ ->
                                   failwith
                                     "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")
                        | _ ->
                            let msg =
                              "ppx_pgsql: internal error: " ^
                                ("Incorrect number of columns returned from query: "
                                   ^
                                   (original_query ^
                                      (".  Columns are: " ^
                                         (String.concat "; "
                                            (List.map
                                               (function
                                                | Some str ->
                                                    Printf.sprintf "%S" str
                                                | None -> "NULL") row))))) in
                            raise (PGOCaml.Error msg)) _rows)))
    let emails_of_userid_with_status userid =
      full_transaction_block @@
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_int64)) userid)]] in
              let split =
                [`Text
                   "SELECT email, validated\n         FROM ocsigen_start.emails WHERE userid = ";
                `Var ("userid", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows ->
                PGOCaml.return
                  (let original_query =
                     "SELECT email, validated\n         FROM ocsigen_start.emails WHERE userid = $userid" in
                   List.rev_map
                     (fun row ->
                        match row with
                        | c0::c1::[] ->
                            (((let open PGOCaml in string_of_string)
                                (try PGOCaml_aux.Option.get c0
                                 with
                                 | _ ->
                                     failwith
                                       "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                              ((let open PGOCaml in bool_of_string)
                                 (try PGOCaml_aux.Option.get c1
                                  with
                                  | _ ->
                                      failwith
                                        "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")))
                        | _ ->
                            let msg =
                              "ppx_pgsql: internal error: " ^
                                ("Incorrect number of columns returned from query: "
                                   ^
                                   (original_query ^
                                      (".  Columns are: " ^
                                         (String.concat "; "
                                            (List.map
                                               (function
                                                | Some str ->
                                                    Printf.sprintf "%S" str
                                                | None -> "NULL") row))))) in
                            raise (PGOCaml.Error msg)) _rows)))
    let email_of_userid userid =
      one full_transaction_block
        ~success:(fun main_email -> Lwt.return main_email)
        ~fail:(Lwt.fail No_such_resource)
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_int64)) userid)]] in
              let split =
                [`Text
                   "SELECT main_email FROM ocsigen_start.users WHERE userid = ";
                `Var ("userid", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows ->
                PGOCaml.return
                  (let original_query =
                     "SELECT main_email FROM ocsigen_start.users WHERE userid = $userid" in
                   List.rev_map
                     (fun row ->
                        match row with
                        | c0::[] ->
                            PGOCaml_aux.Option.map
                              (let open PGOCaml in string_of_string) c0
                        | _ ->
                            let msg =
                              "ppx_pgsql: internal error: " ^
                                ("Incorrect number of columns returned from query: "
                                   ^
                                   (original_query ^
                                      (".  Columns are: " ^
                                         (String.concat "; "
                                            (List.map
                                               (function
                                                | Some str ->
                                                    Printf.sprintf "%S" str
                                                | None -> "NULL") row))))) in
                            raise (PGOCaml.Error msg)) _rows)))
    let is_main_email ~userid  ~email  =
      one full_transaction_block ~success:(fun _ -> Lwt.return_true)
        ~fail:Lwt.return_false
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_int64)) userid)];
                [Some (((let open PGOCaml in string_of_string)) email)]] in
              let split =
                [`Text
                   "SELECT 1 FROM ocsigen_start.users\n            WHERE userid = ";
                `Var ("userid", false, false);
                `Text " AND main_email = ";
                `Var ("email", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows ->
                PGOCaml.return
                  (let original_query =
                     "SELECT 1 FROM ocsigen_start.users\n            WHERE userid = $userid AND main_email = $email" in
                   List.rev_map
                     (fun row ->
                        match row with
                        | c0::[] ->
                            PGOCaml_aux.Option.map
                              (let open PGOCaml in int32_of_string) c0
                        | _ ->
                            let msg =
                              "ppx_pgsql: internal error: " ^
                                ("Incorrect number of columns returned from query: "
                                   ^
                                   (original_query ^
                                      (".  Columns are: " ^
                                         (String.concat "; "
                                            (List.map
                                               (function
                                                | Some str ->
                                                    Printf.sprintf "%S" str
                                                | None -> "NULL") row))))) in
                            raise (PGOCaml.Error msg)) _rows)))
    let add_email_to_user ~userid  ~email  =
      full_transaction_block @@
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_string)) email)];
                [Some (((let open PGOCaml in string_of_int64)) userid)]] in
              let split =
                [`Text
                   "INSERT INTO ocsigen_start.emails (email, userid)\n         VALUES (";
                `Var ("email", false, false);
                `Text ", ";
                `Var ("userid", false, false);
                `Text ")"] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows -> PGOCaml.return ()))
    let remove_email_from_user ~userid  ~email  =
      [%lwt
        let b = is_main_email ~userid ~email in
        if b
        then Lwt.fail Main_email_removal_attempt
        else
          full_transaction_block @@
            ((fun dbh ->
                PGOCaml.bind
                  (let dbh = dbh in
                   let params : string option list list =
                     [[Some (((let open PGOCaml in string_of_int64)) userid)];
                     [Some (((let open PGOCaml in string_of_string)) email)]] in
                   let split =
                     [`Text
                        "DELETE FROM ocsigen_start.emails\n           WHERE userid = ";
                     `Var ("userid", false, false);
                     `Text " AND email = ";
                     `Var ("email", false, false)] in
                   let i = ref 0 in
                   let j = ref 0 in
                   let query =
                     String.concat ""
                       (List.map
                          (function
                           | `Text text -> text
                           | `Var (_varname, false, _) ->
                               let () = incr i in
                               let () = incr j in
                               "$" ^ (string_of_int j.contents)
                           | `Var (_varname, true, _) ->
                               let param = List.nth params i.contents in
                               let () = incr i in
                               "(" ^
                                 ((String.concat ","
                                     (List.map
                                        (fun _ ->
                                           let () = incr j in
                                           "$" ^ (string_of_int j.contents))
                                        param))
                                    ^ ")")) split) in
                   let params = List.flatten params in
                   let name =
                     "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
                   let hash =
                     try PGOCaml.private_data dbh
                     with
                     | Not_found ->
                         let hash = Hashtbl.create 17 in
                         (PGOCaml.set_private_data dbh hash; hash) in
                   let is_prepared = Hashtbl.mem hash name in
                   PGOCaml.bind
                     (if not is_prepared
                      then
                        PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                          (fun () ->
                             Hashtbl.add hash name true; PGOCaml.return ())
                      else PGOCaml.return ())
                     (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
                  (fun _rows -> PGOCaml.return ())))]
    let get_language userid =
      one full_transaction_block
        ~success:(fun language -> Lwt.return language)
        ~fail:(Lwt.fail No_such_resource)
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_int64)) userid)]] in
              let split =
                [`Text
                   "SELECT language FROM ocsigen_start.users WHERE userid = ";
                `Var ("userid", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows ->
                PGOCaml.return
                  (let original_query =
                     "SELECT language FROM ocsigen_start.users WHERE userid = $userid" in
                   List.rev_map
                     (fun row ->
                        match row with
                        | c0::[] ->
                            PGOCaml_aux.Option.map
                              (let open PGOCaml in string_of_string) c0
                        | _ ->
                            let msg =
                              "ppx_pgsql: internal error: " ^
                                ("Incorrect number of columns returned from query: "
                                   ^
                                   (original_query ^
                                      (".  Columns are: " ^
                                         (String.concat "; "
                                            (List.map
                                               (function
                                                | Some str ->
                                                    Printf.sprintf "%S" str
                                                | None -> "NULL") row))))) in
                            raise (PGOCaml.Error msg)) _rows)))
    let get_users ?pattern  () =
      [%lwt
        let l =
          full_transaction_block
            (fun dbh ->
               match pattern with
               | None ->
                   PGOCaml.bind
                     (let dbh = dbh in
                      let params : string option list list = [] in
                      let split =
                        [`Text
                           "SELECT userid, firstname, lastname, avatar,\n                       password IS NOT NULL, language\n                FROM ocsigen_start.users"] in
                      let i = ref 0 in
                      let j = ref 0 in
                      let query =
                        String.concat ""
                          (List.map
                             (function
                              | `Text text -> text
                              | `Var (_varname, false, _) ->
                                  let () = incr i in
                                  let () = incr j in
                                  "$" ^ (string_of_int j.contents)
                              | `Var (_varname, true, _) ->
                                  let param = List.nth params i.contents in
                                  let () = incr i in
                                  "(" ^
                                    ((String.concat ","
                                        (List.map
                                           (fun _ ->
                                              let () = incr j in
                                              "$" ^
                                                (string_of_int j.contents))
                                           param))
                                       ^ ")")) split) in
                      let params = List.flatten params in
                      let name =
                        "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
                      let hash =
                        try PGOCaml.private_data dbh
                        with
                        | Not_found ->
                            let hash = Hashtbl.create 17 in
                            (PGOCaml.set_private_data dbh hash; hash) in
                      let is_prepared = Hashtbl.mem hash name in
                      PGOCaml.bind
                        (if not is_prepared
                         then
                           PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                             (fun () ->
                                Hashtbl.add hash name true; PGOCaml.return ())
                         else PGOCaml.return ())
                        (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
                     (fun _rows ->
                        PGOCaml.return
                          (let original_query =
                             "SELECT userid, firstname, lastname, avatar,\n                       password IS NOT NULL, language\n                FROM ocsigen_start.users" in
                           List.rev_map
                             (fun row ->
                                match row with
                                | c0::c1::c2::c3::c4::c5::[] ->
                                    (((let open PGOCaml in int64_of_string)
                                        (try PGOCaml_aux.Option.get c0
                                         with
                                         | _ ->
                                             failwith
                                               "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                                      ((let open PGOCaml in string_of_string)
                                         (try PGOCaml_aux.Option.get c1
                                          with
                                          | _ ->
                                              failwith
                                                "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                                      ((let open PGOCaml in string_of_string)
                                         (try PGOCaml_aux.Option.get c2
                                          with
                                          | _ ->
                                              failwith
                                                "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                                      (PGOCaml_aux.Option.map
                                         (let open PGOCaml in
                                            string_of_string) c3),
                                      (PGOCaml_aux.Option.map
                                         (let open PGOCaml in bool_of_string)
                                         c4),
                                      (PGOCaml_aux.Option.map
                                         (let open PGOCaml in
                                            string_of_string) c5))
                                | _ ->
                                    let msg =
                                      "ppx_pgsql: internal error: " ^
                                        ("Incorrect number of columns returned from query: "
                                           ^
                                           (original_query ^
                                              (".  Columns are: " ^
                                                 (String.concat "; "
                                                    (List.map
                                                       (function
                                                        | Some str ->
                                                            Printf.sprintf
                                                              "%S" str
                                                        | None -> "NULL") row))))) in
                                    raise (PGOCaml.Error msg)) _rows))
               | Some pattern ->
                   let pattern =
                     "(^" ^ (pattern ^ (")|(.* " ^ (pattern ^ ")"))) in
                   PGOCaml.bind
                     (let dbh = dbh in
                      let params : string option list list =
                        [[Some
                            (((let open PGOCaml in string_of_string)) pattern)]] in
                      let split =
                        [`Text
                           "SELECT userid, firstname, lastname, avatar,\n                      password IS NOT NULL, language\n               FROM ocsigen_start.users\n               WHERE firstname <> '' -- avoids email addresses\n                 AND CONCAT_WS(' ', firstname, lastname) ~* ";
                        `Var ("pattern", false, false)] in
                      let i = ref 0 in
                      let j = ref 0 in
                      let query =
                        String.concat ""
                          (List.map
                             (function
                              | `Text text -> text
                              | `Var (_varname, false, _) ->
                                  let () = incr i in
                                  let () = incr j in
                                  "$" ^ (string_of_int j.contents)
                              | `Var (_varname, true, _) ->
                                  let param = List.nth params i.contents in
                                  let () = incr i in
                                  "(" ^
                                    ((String.concat ","
                                        (List.map
                                           (fun _ ->
                                              let () = incr j in
                                              "$" ^
                                                (string_of_int j.contents))
                                           param))
                                       ^ ")")) split) in
                      let params = List.flatten params in
                      let name =
                        "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
                      let hash =
                        try PGOCaml.private_data dbh
                        with
                        | Not_found ->
                            let hash = Hashtbl.create 17 in
                            (PGOCaml.set_private_data dbh hash; hash) in
                      let is_prepared = Hashtbl.mem hash name in
                      PGOCaml.bind
                        (if not is_prepared
                         then
                           PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                             (fun () ->
                                Hashtbl.add hash name true; PGOCaml.return ())
                         else PGOCaml.return ())
                        (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
                     (fun _rows ->
                        PGOCaml.return
                          (let original_query =
                             "SELECT userid, firstname, lastname, avatar,\n                      password IS NOT NULL, language\n               FROM ocsigen_start.users\n               WHERE firstname <> '' -- avoids email addresses\n                 AND CONCAT_WS(' ', firstname, lastname) ~* $pattern" in
                           List.rev_map
                             (fun row ->
                                match row with
                                | c0::c1::c2::c3::c4::c5::[] ->
                                    (((let open PGOCaml in int64_of_string)
                                        (try PGOCaml_aux.Option.get c0
                                         with
                                         | _ ->
                                             failwith
                                               "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                                      ((let open PGOCaml in string_of_string)
                                         (try PGOCaml_aux.Option.get c1
                                          with
                                          | _ ->
                                              failwith
                                                "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                                      ((let open PGOCaml in string_of_string)
                                         (try PGOCaml_aux.Option.get c2
                                          with
                                          | _ ->
                                              failwith
                                                "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                                      (PGOCaml_aux.Option.map
                                         (let open PGOCaml in
                                            string_of_string) c3),
                                      (PGOCaml_aux.Option.map
                                         (let open PGOCaml in bool_of_string)
                                         c4),
                                      (PGOCaml_aux.Option.map
                                         (let open PGOCaml in
                                            string_of_string) c5))
                                | _ ->
                                    let msg =
                                      "ppx_pgsql: internal error: " ^
                                        ("Incorrect number of columns returned from query: "
                                           ^
                                           (original_query ^
                                              (".  Columns are: " ^
                                                 (String.concat "; "
                                                    (List.map
                                                       (function
                                                        | Some str ->
                                                            Printf.sprintf
                                                              "%S" str
                                                        | None -> "NULL") row))))) in
                                    raise (PGOCaml.Error msg)) _rows))) in
        Lwt.return
          (List.map
             (fun
                (userid, firstname, lastname, avatar, has_password, language)
                ->
                (userid, firstname, lastname, avatar,
                  (has_password = (Some true)), language)) l)]
  end
module Groups =
  struct
    let create ?description  name =
      full_transaction_block @@
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[PGOCaml_aux.Option.map
                    (let open PGOCaml in string_of_string) description];
                [Some (((let open PGOCaml in string_of_string)) name)]] in
              let split =
                [`Text
                   "INSERT INTO ocsigen_start.groups (description, name)\n         VALUES (";
                `Var ("description", false, true);
                `Text ", ";
                `Var ("name", false, false);
                `Text ")"] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows -> PGOCaml.return ()))
    let group_of_name name =
      (full_transaction_block
         (fun dbh ->
            PGOCaml.bind
              (let dbh = dbh in
               let params : string option list list =
                 [[Some (((let open PGOCaml in string_of_string)) name)]] in
               let split =
                 [`Text
                    "SELECT groupid, name, description\n           FROM ocsigen_start.groups WHERE name = ";
                 `Var ("name", false, false)] in
               let i = ref 0 in
               let j = ref 0 in
               let query =
                 String.concat ""
                   (List.map
                      (function
                       | `Text text -> text
                       | `Var (_varname, false, _) ->
                           let () = incr i in
                           let () = incr j in
                           "$" ^ (string_of_int j.contents)
                       | `Var (_varname, true, _) ->
                           let param = List.nth params i.contents in
                           let () = incr i in
                           "(" ^
                             ((String.concat ","
                                 (List.map
                                    (fun _ ->
                                       let () = incr j in
                                       "$" ^ (string_of_int j.contents))
                                    param))
                                ^ ")")) split) in
               let params = List.flatten params in
               let name =
                 "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
               let hash =
                 try PGOCaml.private_data dbh
                 with
                 | Not_found ->
                     let hash = Hashtbl.create 17 in
                     (PGOCaml.set_private_data dbh hash; hash) in
               let is_prepared = Hashtbl.mem hash name in
               PGOCaml.bind
                 (if not is_prepared
                  then
                    PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                      (fun () ->
                         Hashtbl.add hash name true; PGOCaml.return ())
                  else PGOCaml.return ())
                 (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
              (fun _rows ->
                 PGOCaml.return
                   (let original_query =
                      "SELECT groupid, name, description\n           FROM ocsigen_start.groups WHERE name = $name" in
                    List.rev_map
                      (fun row ->
                         match row with
                         | c0::c1::c2::[] ->
                             (((let open PGOCaml in int64_of_string)
                                 (try PGOCaml_aux.Option.get c0
                                  with
                                  | _ ->
                                      failwith
                                        "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                               ((let open PGOCaml in string_of_string)
                                  (try PGOCaml_aux.Option.get c1
                                   with
                                   | _ ->
                                       failwith
                                         "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                               (PGOCaml_aux.Option.map
                                  (let open PGOCaml in string_of_string) c2))
                         | _ ->
                             let msg =
                               "ppx_pgsql: internal error: " ^
                                 ("Incorrect number of columns returned from query: "
                                    ^
                                    (original_query ^
                                       (".  Columns are: " ^
                                          (String.concat "; "
                                             (List.map
                                                (function
                                                 | Some str ->
                                                     Printf.sprintf "%S" str
                                                 | None -> "NULL") row))))) in
                             raise (PGOCaml.Error msg)) _rows))))
        >>=
        (function | r::[] -> Lwt.return r | _ -> Lwt.fail No_such_resource)
    let add_user_in_group ~groupid  ~userid  =
      full_transaction_block @@
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_int64)) userid)];
                [Some (((let open PGOCaml in string_of_int64)) groupid)]] in
              let split =
                [`Text
                   "INSERT INTO ocsigen_start.user_groups (userid, groupid)\n         VALUES (";
                `Var ("userid", false, false);
                `Text ", ";
                `Var ("groupid", false, false);
                `Text ")"] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows -> PGOCaml.return ()))
    let remove_user_in_group ~groupid  ~userid  =
      full_transaction_block @@
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_int64)) groupid)];
                [Some (((let open PGOCaml in string_of_int64)) userid)]] in
              let split =
                [`Text
                   "DELETE FROM ocsigen_start.user_groups\n         WHERE groupid = ";
                `Var ("groupid", false, false);
                `Text " AND userid = ";
                `Var ("userid", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows -> PGOCaml.return ()))
    let in_group ?dbh  ~groupid  ~userid  () =
      one
        (match dbh with
         | None -> full_transaction_block
         | Some dbh -> (fun f -> f dbh)) ~success:(fun _ -> Lwt.return_true)
        ~fail:Lwt.return_false
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_int64)) groupid)];
                [Some (((let open PGOCaml in string_of_int64)) userid)]] in
              let split =
                [`Text
                   "SELECT 1 FROM ocsigen_start.user_groups\n           WHERE groupid = ";
                `Var ("groupid", false, false);
                `Text " AND userid = ";
                `Var ("userid", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows ->
                PGOCaml.return
                  (let original_query =
                     "SELECT 1 FROM ocsigen_start.user_groups\n           WHERE groupid = $groupid AND userid = $userid" in
                   List.rev_map
                     (fun row ->
                        match row with
                        | c0::[] ->
                            PGOCaml_aux.Option.map
                              (let open PGOCaml in int32_of_string) c0
                        | _ ->
                            let msg =
                              "ppx_pgsql: internal error: " ^
                                ("Incorrect number of columns returned from query: "
                                   ^
                                   (original_query ^
                                      (".  Columns are: " ^
                                         (String.concat "; "
                                            (List.map
                                               (function
                                                | Some str ->
                                                    Printf.sprintf "%S" str
                                                | None -> "NULL") row))))) in
                            raise (PGOCaml.Error msg)) _rows)))
    let all () =
      full_transaction_block @@
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list = [] in
              let split =
                [`Text
                   "SELECT groupid, name, description FROM ocsigen_start.groups"] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows ->
                PGOCaml.return
                  (let original_query =
                     "SELECT groupid, name, description FROM ocsigen_start.groups" in
                   List.rev_map
                     (fun row ->
                        match row with
                        | c0::c1::c2::[] ->
                            (((let open PGOCaml in int64_of_string)
                                (try PGOCaml_aux.Option.get c0
                                 with
                                 | _ ->
                                     failwith
                                       "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                              ((let open PGOCaml in string_of_string)
                                 (try PGOCaml_aux.Option.get c1
                                  with
                                  | _ ->
                                      failwith
                                        "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")),
                              (PGOCaml_aux.Option.map
                                 (let open PGOCaml in string_of_string) c2))
                        | _ ->
                            let msg =
                              "ppx_pgsql: internal error: " ^
                                ("Incorrect number of columns returned from query: "
                                   ^
                                   (original_query ^
                                      (".  Columns are: " ^
                                         (String.concat "; "
                                            (List.map
                                               (function
                                                | Some str ->
                                                    Printf.sprintf "%S" str
                                                | None -> "NULL") row))))) in
                            raise (PGOCaml.Error msg)) _rows)))
  end
module Phone =
  struct
    let add userid number =
      without_transaction @@
        (fun dbh ->
           [%lwt
             let l =
               PGOCaml.bind
                 (let dbh = dbh in
                  let params : string option list list =
                    [[Some (((let open PGOCaml in string_of_string)) number)];
                    [Some (((let open PGOCaml in string_of_int64)) userid)]] in
                  let split =
                    [`Text
                       "INSERT INTO ocsigen_start.phones (number, userid)\n           VALUES (";
                    `Var ("number", false, false);
                    `Text ", ";
                    `Var ("userid", false, false);
                    `Text
                      ")\n           ON CONFLICT DO NOTHING\n           RETURNING 0"] in
                  let i = ref 0 in
                  let j = ref 0 in
                  let query =
                    String.concat ""
                      (List.map
                         (function
                          | `Text text -> text
                          | `Var (_varname, false, _) ->
                              let () = incr i in
                              let () = incr j in
                              "$" ^ (string_of_int j.contents)
                          | `Var (_varname, true, _) ->
                              let param = List.nth params i.contents in
                              let () = incr i in
                              "(" ^
                                ((String.concat ","
                                    (List.map
                                       (fun _ ->
                                          let () = incr j in
                                          "$" ^ (string_of_int j.contents))
                                       param))
                                   ^ ")")) split) in
                  let params = List.flatten params in
                  let name =
                    "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
                  let hash =
                    try PGOCaml.private_data dbh
                    with
                    | Not_found ->
                        let hash = Hashtbl.create 17 in
                        (PGOCaml.set_private_data dbh hash; hash) in
                  let is_prepared = Hashtbl.mem hash name in
                  PGOCaml.bind
                    (if not is_prepared
                     then
                       PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                         (fun () ->
                            Hashtbl.add hash name true; PGOCaml.return ())
                     else PGOCaml.return ())
                    (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
                 (fun _rows ->
                    PGOCaml.return
                      (let original_query =
                         "INSERT INTO ocsigen_start.phones (number, userid)\n           VALUES ($number, $userid)\n           ON CONFLICT DO NOTHING\n           RETURNING 0" in
                       List.rev_map
                         (fun row ->
                            match row with
                            | c0::[] ->
                                PGOCaml_aux.Option.map
                                  (let open PGOCaml in int32_of_string) c0
                            | _ ->
                                let msg =
                                  "ppx_pgsql: internal error: " ^
                                    ("Incorrect number of columns returned from query: "
                                       ^
                                       (original_query ^
                                          (".  Columns are: " ^
                                             (String.concat "; "
                                                (List.map
                                                   (function
                                                    | Some str ->
                                                        Printf.sprintf "%S"
                                                          str
                                                    | None -> "NULL") row))))) in
                                raise (PGOCaml.Error msg)) _rows)) in
             Lwt.return (match l with | _::[] -> true | _ -> false)])
    let exists number =
      without_transaction @@
        (fun dbh ->
           [%lwt
             match full_transaction_block @@
                     (fun dbh ->
                        PGOCaml.bind
                          (let dbh = dbh in
                           let params : string option list list =
                             [[Some
                                 (((let open PGOCaml in string_of_string))
                                    number)]] in
                           let split =
                             [`Text
                                "SELECT 1 FROM ocsigen_start.phones WHERE number = ";
                             `Var ("number", false, false)] in
                           let i = ref 0 in
                           let j = ref 0 in
                           let query =
                             String.concat ""
                               (List.map
                                  (function
                                   | `Text text -> text
                                   | `Var (_varname, false, _) ->
                                       let () = incr i in
                                       let () = incr j in
                                       "$" ^ (string_of_int j.contents)
                                   | `Var (_varname, true, _) ->
                                       let param = List.nth params i.contents in
                                       let () = incr i in
                                       "(" ^
                                         ((String.concat ","
                                             (List.map
                                                (fun _ ->
                                                   let () = incr j in
                                                   "$" ^
                                                     (string_of_int
                                                        j.contents)) param))
                                            ^ ")")) split) in
                           let params = List.flatten params in
                           let name =
                             "ppx_pgsql." ^
                               (Digest.to_hex (Digest.string query)) in
                           let hash =
                             try PGOCaml.private_data dbh
                             with
                             | Not_found ->
                                 let hash = Hashtbl.create 17 in
                                 (PGOCaml.set_private_data dbh hash; hash) in
                           let is_prepared = Hashtbl.mem hash name in
                           PGOCaml.bind
                             (if not is_prepared
                              then
                                PGOCaml.bind
                                  (PGOCaml.prepare dbh ~name ~query ())
                                  (fun () ->
                                     Hashtbl.add hash name true;
                                     PGOCaml.return ())
                              else PGOCaml.return ())
                             (fun () ->
                                PGOCaml.execute_rev dbh ~name ~params ()))
                          (fun _rows ->
                             PGOCaml.return
                               (let original_query =
                                  "SELECT 1 FROM ocsigen_start.phones WHERE number = $number" in
                                List.rev_map
                                  (fun row ->
                                     match row with
                                     | c0::[] ->
                                         PGOCaml_aux.Option.map
                                           (let open PGOCaml in
                                              int32_of_string) c0
                                     | _ ->
                                         let msg =
                                           "ppx_pgsql: internal error: " ^
                                             ("Incorrect number of columns returned from query: "
                                                ^
                                                (original_query ^
                                                   (".  Columns are: " ^
                                                      (String.concat "; "
                                                         (List.map
                                                            (function
                                                             | Some str ->
                                                                 Printf.sprintf
                                                                   "%S" str
                                                             | None -> "NULL")
                                                            row))))) in
                                         raise (PGOCaml.Error msg)) _rows)))
             with
             | _::_ -> Lwt.return_true
             | [] -> Lwt.return_false])
    let userid number =
      without_transaction @@
        (fun dbh ->
           [%lwt
             match full_transaction_block @@
                     (fun dbh ->
                        PGOCaml.bind
                          (let dbh = dbh in
                           let params : string option list list =
                             [[Some
                                 (((let open PGOCaml in string_of_string))
                                    number)]] in
                           let split =
                             [`Text
                                "SELECT userid FROM ocsigen_start.phones WHERE number = ";
                             `Var ("number", false, false)] in
                           let i = ref 0 in
                           let j = ref 0 in
                           let query =
                             String.concat ""
                               (List.map
                                  (function
                                   | `Text text -> text
                                   | `Var (_varname, false, _) ->
                                       let () = incr i in
                                       let () = incr j in
                                       "$" ^ (string_of_int j.contents)
                                   | `Var (_varname, true, _) ->
                                       let param = List.nth params i.contents in
                                       let () = incr i in
                                       "(" ^
                                         ((String.concat ","
                                             (List.map
                                                (fun _ ->
                                                   let () = incr j in
                                                   "$" ^
                                                     (string_of_int
                                                        j.contents)) param))
                                            ^ ")")) split) in
                           let params = List.flatten params in
                           let name =
                             "ppx_pgsql." ^
                               (Digest.to_hex (Digest.string query)) in
                           let hash =
                             try PGOCaml.private_data dbh
                             with
                             | Not_found ->
                                 let hash = Hashtbl.create 17 in
                                 (PGOCaml.set_private_data dbh hash; hash) in
                           let is_prepared = Hashtbl.mem hash name in
                           PGOCaml.bind
                             (if not is_prepared
                              then
                                PGOCaml.bind
                                  (PGOCaml.prepare dbh ~name ~query ())
                                  (fun () ->
                                     Hashtbl.add hash name true;
                                     PGOCaml.return ())
                              else PGOCaml.return ())
                             (fun () ->
                                PGOCaml.execute_rev dbh ~name ~params ()))
                          (fun _rows ->
                             PGOCaml.return
                               (let original_query =
                                  "SELECT userid FROM ocsigen_start.phones WHERE number = $number" in
                                List.rev_map
                                  (fun row ->
                                     match row with
                                     | c0::[] ->
                                         (let open PGOCaml in int64_of_string)
                                           (try PGOCaml_aux.Option.get c0
                                            with
                                            | _ ->
                                                failwith
                                                  "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")
                                     | _ ->
                                         let msg =
                                           "ppx_pgsql: internal error: " ^
                                             ("Incorrect number of columns returned from query: "
                                                ^
                                                (original_query ^
                                                   (".  Columns are: " ^
                                                      (String.concat "; "
                                                         (List.map
                                                            (function
                                                             | Some str ->
                                                                 Printf.sprintf
                                                                   "%S" str
                                                             | None -> "NULL")
                                                            row))))) in
                                         raise (PGOCaml.Error msg)) _rows)))
             with
             | userid::_ -> Lwt.return (Some userid)
             | [] -> Lwt.return None])
    let delete userid number =
      without_transaction @@
        (fun dbh ->
           PGOCaml.bind
             (let dbh = dbh in
              let params : string option list list =
                [[Some (((let open PGOCaml in string_of_int64)) userid)];
                [Some (((let open PGOCaml in string_of_string)) number)]] in
              let split =
                [`Text
                   "DELETE FROM ocsigen_start.phones\n         WHERE userid = ";
                `Var ("userid", false, false);
                `Text " AND number = ";
                `Var ("number", false, false)] in
              let i = ref 0 in
              let j = ref 0 in
              let query =
                String.concat ""
                  (List.map
                     (function
                      | `Text text -> text
                      | `Var (_varname, false, _) ->
                          let () = incr i in
                          let () = incr j in "$" ^ (string_of_int j.contents)
                      | `Var (_varname, true, _) ->
                          let param = List.nth params i.contents in
                          let () = incr i in
                          "(" ^
                            ((String.concat ","
                                (List.map
                                   (fun _ ->
                                      let () = incr j in
                                      "$" ^ (string_of_int j.contents)) param))
                               ^ ")")) split) in
              let params = List.flatten params in
              let name = "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
              let hash =
                try PGOCaml.private_data dbh
                with
                | Not_found ->
                    let hash = Hashtbl.create 17 in
                    (PGOCaml.set_private_data dbh hash; hash) in
              let is_prepared = Hashtbl.mem hash name in
              PGOCaml.bind
                (if not is_prepared
                 then
                   PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                     (fun () -> Hashtbl.add hash name true; PGOCaml.return ())
                 else PGOCaml.return ())
                (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
             (fun _rows -> PGOCaml.return ()))
    let get_list userid =
      without_transaction @@
        (fun dbh ->
           full_transaction_block @@
             (fun dbh ->
                PGOCaml.bind
                  (let dbh = dbh in
                   let params : string option list list =
                     [[Some (((let open PGOCaml in string_of_int64)) userid)]] in
                   let split =
                     [`Text
                        "SELECT number FROM ocsigen_start.phones WHERE userid = ";
                     `Var ("userid", false, false)] in
                   let i = ref 0 in
                   let j = ref 0 in
                   let query =
                     String.concat ""
                       (List.map
                          (function
                           | `Text text -> text
                           | `Var (_varname, false, _) ->
                               let () = incr i in
                               let () = incr j in
                               "$" ^ (string_of_int j.contents)
                           | `Var (_varname, true, _) ->
                               let param = List.nth params i.contents in
                               let () = incr i in
                               "(" ^
                                 ((String.concat ","
                                     (List.map
                                        (fun _ ->
                                           let () = incr j in
                                           "$" ^ (string_of_int j.contents))
                                        param))
                                    ^ ")")) split) in
                   let params = List.flatten params in
                   let name =
                     "ppx_pgsql." ^ (Digest.to_hex (Digest.string query)) in
                   let hash =
                     try PGOCaml.private_data dbh
                     with
                     | Not_found ->
                         let hash = Hashtbl.create 17 in
                         (PGOCaml.set_private_data dbh hash; hash) in
                   let is_prepared = Hashtbl.mem hash name in
                   PGOCaml.bind
                     (if not is_prepared
                      then
                        PGOCaml.bind (PGOCaml.prepare dbh ~name ~query ())
                          (fun () ->
                             Hashtbl.add hash name true; PGOCaml.return ())
                      else PGOCaml.return ())
                     (fun () -> PGOCaml.execute_rev dbh ~name ~params ()))
                  (fun _rows ->
                     PGOCaml.return
                       (let original_query =
                          "SELECT number FROM ocsigen_start.phones WHERE userid = $userid" in
                        List.rev_map
                          (fun row ->
                             match row with
                             | c0::[] ->
                                 (let open PGOCaml in string_of_string)
                                   (try PGOCaml_aux.Option.get c0
                                    with
                                    | _ ->
                                        failwith
                                          "ppx_pgsql's nullability heuristic has failed - use \"nullable-results\"")
                             | _ ->
                                 let msg =
                                   "ppx_pgsql: internal error: " ^
                                     ("Incorrect number of columns returned from query: "
                                        ^
                                        (original_query ^
                                           (".  Columns are: " ^
                                              (String.concat "; "
                                                 (List.map
                                                    (function
                                                     | Some str ->
                                                         Printf.sprintf "%S"
                                                           str
                                                     | None -> "NULL") row))))) in
                                 raise (PGOCaml.Error msg)) _rows))))
  end
