(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright (C) Université Paris Diderot, CNRS, INRIA, Be Sport.
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

open%shared Lwt.Syntax
open%shared Eliom.Content.Html.F
open%client Js_of_ocaml

let%shared log_section = Logs.Src.create "os:page"

[%%shared
exception Predicate_failed of exn option

type content =
  { html_attrs : Html_types.html_attrib Eliom.Content.Html.attrib list
  ; title : string option
  ; head : Html_types.head_content_fun elt list
  ; body_attrs : Html_types.body_attrib Eliom.Content.Html.attrib list
  ; body : Html_types.body_content elt list
  }]

let%shared content ?(html_a = []) ?(a = []) ?title ?(head = []) body =
  let html_attrs =
    if Eliom.Client.is_client_app ()
    then a_class ["os-client-app"] :: html_a
    else html_a
  in
  { html_attrs
  ; title
  ; head :> Html_types.head_content_fun elt list
  ; body_attrs = a
  ; body :> Html_types.body_content elt list
  }

(* The exception that made the error page, without the wrapper of a failing
   predicate. *)
let%shared rec cause = function
  | Predicate_failed (Some exc) -> cause exc
  | exc -> exc

(* The status of the error page for the exceptions known on both sides. *)
let%shared shared_status exc =
  match cause exc with
  | Session.Not_connected | Session.Permission_denied | Predicate_failed None ->
      Some `Forbidden
  | Eliom.Common.Eliom_404 | Handlers.No_such_resource -> Some `Not_found
  | _ -> None

(* The HTTP status of the error page for [exc]: 403 when the user may not see
   the page, 404 when what it shows does not exist, 500 otherwise. No
   WWW-Authenticate challenge is sent, hence 403 rather than 401 for a
   visitor who is not connected. [Not_found] is a 500, as in Eliom: it
   usually comes from a bug in the handler (Hashtbl.find, List.assoc), which
   a 404 would hide. *)
let%server error_status exc =
  match shared_status exc with
  | Some status -> status
  | None -> (
    match cause exc with
    | User.No_such_user | Db.No_such_user | Db.No_such_resource -> `Not_found
    | _ -> `Internal_server_error
  )

(* On the client, Eliom.Registration.set_status does nothing, but the status
   still chooses the log level. *)
let%client error_status exc =
  Option.value ~default:`Internal_server_error (shared_status exc)

(* The log message, with the path of the request but not its parameters,
   which may hold keys (see Services.action_link_service). *)
let%shared error_message exc : (_, unit) Logs.msgf =
 fun fmt ->
  let what =
    match exc with
    | Predicate_failed None -> "the predicate returned false"
    | Predicate_failed (Some exc) ->
        "the predicate raised " ^ Printexc.to_string (cause exc)
    | exc -> "exception " ^ Printexc.to_string exc
  in
  fmt "error page for %s: %s"
    (Eliom.Request_info.get_original_full_path_string ())
    what

(* The error page may not show the exception, so log it: as an error for a
   500, which usually comes from a bug, and as a debug message for a 403 or a
   404, which are part of the normal flow. *)
let%shared log_error status exc =
  let level =
    match status with
    | `Internal_server_error -> Logs.Error
    | `Forbidden | `Not_found -> Logs.Debug
  in
  Logs.msg ~src:log_section level (error_message exc)

[%%shared
module type PAGE = sig
  val title : string
  val js : string list list
  val local_js : string list list
  val css : string list list
  val local_css : string list list

  val other_head :
    unit -> Html_types.head_content_fun Eliom.Content.Html.elt list

  val default_error_page : 'a -> 'b -> exn -> content Lwt.t

  val default_connected_error_page :
    Types.User.id option -> 'a -> 'b -> exn -> content Lwt.t

  val default_predicate : 'a -> 'b -> bool Lwt.t

  val default_connected_predicate :
    Types.User.id option -> 'a -> 'b -> bool Lwt.t
end

module Default_config = struct
  let title = ""
  let js : string list list = []
  let css : string list list = []
  let local_js : string list list = []
  let local_css : string list list = []

  let other_head () : Html_types.head_content_fun Eliom.Content.Html.elt list =
    []

  let err_page exn =
    let de =
      if ~%(Ocsigen.Config.get_debugmode ())
      then [p [txt "Debug info: "; em [txt (Printexc.to_string exn)]]]
      else []
    in
    let l =
      match exn with
      | Session.Not_connected ->
          p [txt "You must be connected to see this page."] :: de
      | _ -> de
    in
    Lwt.return (content [div ~a:[a_class ["errormsg"]] (h2 [txt "Error"] :: l)])

  let default_predicate _ _ = Lwt.return_true
  let default_connected_predicate _ _ _ = Lwt.return_true
  let default_error_page _ _ exn = err_page exn
  let default_connected_error_page _ _ _ exn = err_page exn
end

module Make (C : PAGE) = struct
  let css = List.map (fun cssname -> "css" :: cssname) C.css
  let js = List.map (fun jsname -> "js" :: jsname) C.js

  (* Local assets always have relative links. *)
  let local_css =
    List.map
      (fun cssname ->
        Eliom.Content.Html.F.css_link
          ~uri:
            (make_uri ~absolute:false
               ~service:(Eliom.Service.static_dir ())
               ("css" :: cssname)
            )
          ()
      )
      C.local_css

  let local_js =
    List.map
      (fun cssname ->
        Eliom.Content.Html.F.js_script
          ~a:[a_defer ()]
          ~uri:
            (make_uri ~absolute:false
               ~service:(Eliom.Service.static_dir ())
               ("js" :: cssname)
            )
          ()
      )
      C.local_js

  let make_page content =
    let title = match content.title with Some t -> t | None -> C.title in
    let connected_attr =
      if Current_user.Opt.get_current_userid () <> None
      then a_class ["os-connected"]
      else a_class ["os-not-connected"]
    in
    let platform_attr =
      a_onload
        [%client
          fun _ : unit ->
            let platform = Js.string (Platform.css_class (Platform.get ())) in
            Dom_html.document##.documentElement##.classList##add platform]
    in
    html ~a:content.html_attrs
      (Eliom.Tools.F.head ~title ~css ~js
         ~other:(local_css @ local_js @ content.head @ C.other_head ())
         ()
      )
      (body
         ~a:(platform_attr :: connected_attr :: content.body_attrs)
         content.body
      )

  (* Log the exception and set the status before the fallback builds the
     error page, which may set another status. *)
  let set_error_status exc =
    let status = error_status exc in
    log_error status exc;
    Eliom.Registration.set_status status

  let page
      ?(predicate = C.default_predicate)
      ?(fallback = C.default_error_page)
      f
      gp
      pp =
    let fallback gp pp exc = set_error_status exc; fallback gp pp exc in
    let* content =
      Lwt.catch
        (fun () ->
          let* b = predicate gp pp in
          if b
          then Lwt.catch (fun () -> f gp pp) (fun exc -> fallback gp pp exc)
          else fallback gp pp (Predicate_failed None)
        )
        (fun exc -> fallback gp pp (Predicate_failed (Some exc)))
    in
    Lwt.return (make_page content)

  let connected_page
      ?allow
      ?deny
      ?(predicate = C.default_connected_predicate)
      ?(fallback = C.default_connected_error_page)
      f
      gp
      pp =
    let fallback myid_o gp pp exc =
      set_error_status exc; fallback myid_o gp pp exc
    in
    let f_wrapped myid gp pp =
      Lwt.catch
        (fun () ->
          let* b = predicate (Some myid) gp pp in
          if b
          then
            Lwt.catch
              (fun () -> f myid gp pp)
              (fun exc -> fallback (Some myid) gp pp exc)
          else Lwt.fail (Predicate_failed None)
        )
        (function
          | Predicate_failed _ as exc -> fallback (Some myid) gp pp exc
          | exc -> fallback (Some myid) gp pp (Predicate_failed (Some exc))
          )
    in
    let* content =
      Lwt.catch
        (fun () ->
          Session.connected_fun ?allow ?deny
            ~deny_fun:(fun myid_o ->
              fallback myid_o gp pp Session.Permission_denied
            )
            f_wrapped gp pp
        )
        (function
          | Session.Not_connected as exc -> fallback None gp pp exc
          | exc -> Lwt.reraise exc
          )
    in
    Lwt.return (make_page content)

  module Opt = struct
    let connected_page
        ?allow
        ?deny
        ?(predicate = C.default_connected_predicate)
        ?(fallback = C.default_connected_error_page)
        f
        gp
        pp =
      let fallback myid_o gp pp exc =
        set_error_status exc; fallback myid_o gp pp exc
      in
      let f_wrapped (myid_o : Types.User.id option) gp pp =
        Lwt.catch
          (fun () ->
            let* b = predicate myid_o gp pp in
            if b
            then
              Lwt.catch
                (fun () -> f myid_o gp pp)
                (fun exc -> fallback myid_o gp pp exc)
            else Lwt.fail (Predicate_failed None)
          )
          (function
            | Predicate_failed _ as exc -> fallback myid_o gp pp exc
            | exc -> fallback myid_o gp pp (Predicate_failed (Some exc))
            )
      in
      let* content =
        Session.Opt.connected_fun ?allow ?deny
          ~deny_fun:(fun myid_o ->
            fallback myid_o gp pp Session.Permission_denied
          )
          f_wrapped gp pp
      in
      Lwt.return (make_page content)
  end
end]
