(* Copyright Vincent Balat *)

(* Call this to add an action to be done
   when the process start in connected mode, or when the user logs in *)
let (at_start_connected_process, start_connected_process_action) =
  let r = ref Lwt.return in
  ((fun f ->
    let oldf= !r in
    r:= (fun () -> lwt () = oldf () in f ())),
   (fun () -> !r ()))


module O = Eba_main.Make(struct
  let app_name = "myproject"
  let capitalized_app_name = "myproject"
  let css_list = [
    ["font-awesome.css"];
    ["myproject.css"]
  ]
  let js_list = [
    ["jquery-ui.min.js"];
    ["accents.js"];
    ["unix.js"]
  ]
  let open_session = Lwt.return
  let close_session = Lwt.return
  let start_process = Lwt.return
  let start_connected_process () = start_connected_process_action ()
end)

include O


{client{

  let myid_str =
    let r = ref None in
    (fun () -> match !r, !Eba_sessions.me with
      | Some _, _ -> !r
      | None, None -> None
      | None, Some u ->
        r := Some (Int64.to_string u.Eba_common0.userid); !r)

 }}
