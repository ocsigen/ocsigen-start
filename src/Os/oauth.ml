(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright (C) Be Sport, Tarides.
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

open Lwt.Syntax

let log_src = Core_oauth.log_src

(* All durations are in seconds. *)

(* How long to wait for the key set before giving up. *)
let fetch_timeout = 10.

(* How long to keep the keys when the response has no max-age directive. *)
let default_max_age = 3600

(* The keys are fetched again this long before they expire. *)
let refresh_margin = 60.

(* The minimum time between two fetches of the same key set, whatever the
   max-age directive or the key ids of the tokens. *)
let min_fetch_interval = 60.

(* After a failed fetch, the next one waits this long. *)
let retry_delay = 10.

type cache =
  { mutable keys : Core_oauth.keys option
  ; mutable fetched_at : float  (** Time of the last fetch attempt. *)
  ; mutable refresh_at : float  (** Time of the next fetch. *)
  ; mutable pending : Core_oauth.keys option Lwt.t option
    (** The fetch in progress, if any. *) }

(* The key sets, by URL. *)
let caches : (string, cache) Hashtbl.t = Hashtbl.create 2

let cache_of uri =
  let url = Uri.to_string uri in
  match Hashtbl.find_opt caches url with
  | Some cache -> cache
  | None ->
      let cache =
        {keys = None; fetched_at = 0.; refresh_at = 0.; pending = None}
      in
      Hashtbl.add caches url cache;
      cache

(* [fetch uri] is the key set at [uri] and its max-age. *)
let fetch uri =
  let get () =
    let* response, body = Cohttp_lwt_unix.Client.get uri in
    let* text = Cohttp_lwt.Body.to_string body in
    Lwt.return (response, text)
  in
  Lwt.catch
    (fun () ->
       let+ response, text = Lwt_unix.with_timeout fetch_timeout get in
       match Cohttp.Response.status response with
       | `OK -> (
         match Core_oauth.keys_of_string text with
         | Ok keys ->
             let max_age =
               Option.bind
                 (Cohttp.Header.get
                    (Cohttp.Response.headers response)
                    "cache-control")
                 Core_oauth.max_age
             in
             Ok (keys, Option.value max_age ~default:default_max_age)
         | Error msg -> Error ("invalid key set: " ^ msg))
       | status -> Error ("HTTP status " ^ Cohttp.Code.string_of_status status))
    (* The exceptions of a network request (resolution, connection, TLS,
       timeout...) do not form a closed set: all of them are reported. *)
    (fun exn -> Lwt.return (Error (Printexc.to_string exn)))

let refresh uri cache =
  match cache.pending with
  | Some pending -> Lwt.protected pending
  | None ->
      let now = Unix.gettimeofday () in
      cache.fetched_at <- now;
      let fetching =
        let+ result = fetch uri in
        (match result with
        | Ok (keys, max_age) ->
            Logs.debug ~src:log_src (fun m ->
              m "Fetched the keys at %a, kept %ds" Uri.pp uri max_age);
            cache.keys <- Some keys;
            cache.refresh_at <-
              now
              +. Float.max min_fetch_interval
                   (Float.of_int max_age -. refresh_margin)
        | Error msg ->
            Logs.err ~src:log_src (fun m ->
              m "Cannot fetch the keys at %a: %s" Uri.pp uri msg);
            (* Keep the previous keys, if any, until the next attempt. *)
            cache.refresh_at <- now +. retry_delay);
        cache.keys
      in
      (* Concurrent requests share the fetch in progress. It is protected
         from their cancellation, and forgotten once it is over. *)
      if Lwt.is_sleeping fetching
      then (
        cache.pending <- Some fetching;
        Lwt.on_termination fetching (fun () -> cache.pending <- None));
      Lwt.protected fetching

(* With [~unknown_key:true], the token names a key id absent from the cached
   keys: the provider may have published new keys since the last fetch. *)
let get_keys ~unknown_key uri =
  let cache = cache_of uri in
  let now = Unix.gettimeofday () in
  if
    now >= cache.refresh_at
    || (unknown_key && now -. cache.fetched_at >= min_fetch_interval)
  then refresh uri cache
  else Lwt.return cache.keys

let validate_token ~jwks_uri ~allowed_issuers ~allowed_audiences id_token =
  let validate ~unknown_key =
    let+ keys = get_keys ~unknown_key jwks_uri in
    Option.map
      (fun keys ->
         Core_oauth.validate ~now:(Unix.gettimeofday ()) ~keys ~allowed_issuers
           ~allowed_audiences id_token)
      keys
  in
  let* result =
    let* result = validate ~unknown_key:false in
    match result with
    | Some (Error (Core_oauth.Unknown_key _)) -> validate ~unknown_key:true
    | Some (Ok _ | Error Core_oauth.(Malformed _ | Rejected _)) | None ->
        Lwt.return result
  in
  match result with
  | Some (Ok claims) -> Lwt.return_some claims
  | Some (Error e) ->
      Logs.info ~src:log_src (fun m ->
        m "Invalid ID token: %a" Core_oauth.pp_error e);
      Lwt.return_none
  | None ->
      Logs.info ~src:log_src (fun m ->
        m "ID token not checked: no keys from %a" Uri.pp jwks_uri);
      Lwt.return_none

module Google = struct
  let jwks_uri = Uri.of_string "https://www.googleapis.com/oauth2/v3/certs"
  let issuers = ["accounts.google.com"; "https://accounts.google.com"]

  let validate ~client_ids id_token =
    validate_token ~jwks_uri ~allowed_issuers:issuers
      ~allowed_audiences:client_ids id_token
end
