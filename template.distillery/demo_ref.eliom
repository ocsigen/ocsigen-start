(* service for this demo *)
let%server service =
  Eliom_service.create
    ~path:(Eliom_service.Path ["demo-ref"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

(* make service available on the client (for mobile app) *)
let%client service = ~%service

(* name for demo menu *)
let%shared name = "Eliom references + OS dates"

(* class for the page containing this demo (for internal use) *)
let%shared page_class = "os-page-demo-ref"

(* an Eliom_ref storing the last time the user visited the current
   page *)
let%server last_visit =
  Eliom_reference.eref
    ~persistent:"demo_last_visit"
    ~scope:Eliom_common.default_group_scope
    None

(* read & reset last_visit *)
let get_reset_last_visit () =
  let%lwt v  = Eliom_reference.get last_visit in
  let%lwt () = Eliom_reference.set last_visit (Some (Os_date.now ())) in
  Lwt.return v

(* make get_reset_last_visit available to the client *)
let%client get_reset_last_visit =
  ~%(Eliom_client.server_function [%derive.json : unit]
       get_reset_last_visit)

(* call get_reset_last_visit and produce pretty message *)
let%shared get_reset_last_visit_message () =
  let%lwt last_visit = get_reset_last_visit () in
  match last_visit with
  | None ->
    Lwt.return "This is your first visit."
  | Some last_visit ->
    Lwt.return
      ("The last time you visited was: "
       ^ Os_date.smart_time last_visit)

(* generate page for this demo *)
let%shared page () =
  let%lwt last_visit_message = get_reset_last_visit_message () in
  Lwt.return Eliom_content.Html.[
    D.p [D.pcdata "We use an Eliom_ref to record the last time you \
                   visited this page."];
    D.p [D.pcdata last_visit_message];
    D.p [D.pcdata "The reference has been reset. Come back later!"]
  ]
