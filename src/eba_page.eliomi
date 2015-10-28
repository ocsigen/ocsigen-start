(* Eliom-base-app
 * http://www.ocsigen.org/eliom-base-app
 *
 * Copyright (C) 2014
 *      Charly Chevalier
 *      Vincent Balat
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

{shared{
(** Functor defining wrappers for services handlers returning pages. *)

exception Predicate_failed of (exn option)

(** The signature of the module to be given as parameter to the functor.
    It allows to personnalize your pages (CSS, JS, etc).
*)
module type PAGE = sig

  (** [title] corresponds to the html tag <title>, it will be inserted on all
      pages.  *)
  val title : string

  (** [js] corresponds to the Javascript files to include into each page.
      Eba will automatically preprend the suffix "js/" as directory.  *)
  val js : string list list

  (** [css] (same as [js] but for style sheet files),
      Eba will automatically prepend the suffix "css/" as directory.  *)
  val css : string list list

  (** [other_head] is a list of custom elements to add in the head section.
      It can be used to add <meta> elements, for example. *)
  val other_head : [ Html5_types.head_content_fun ] Eliom_content.Html5.elt list

  (** Default error page. *)
  val default_error_page :
    'a -> 'b -> exn ->
    [ Html5_types.body_content ] Eliom_content.Html5.elt list Lwt.t

  (** Default error page for connected pages. *)
  val default_connected_error_page :
    int64 option -> 'a -> 'b -> exn ->
    [ Html5_types.body_content ] Eliom_content.Html5.elt list Lwt.t

  (** Default predicate. *)
  val default_predicate : 'a -> 'b -> bool Lwt.t

  (** Default predicate for connected pages. *)
  val default_connected_predicate : int64 option -> 'a -> 'b -> bool Lwt.t

end

module Default_config : PAGE

(** An abstract type describing the content of a page *)
type content

(** Specifies a page with an optional title, some optional extra
    headers and a given body *)
val content :
  ?title:string ->
  ?headers : [< Html5_types.head_content_fun] Eliom_content.Html5.elt list ->
  [< Html5_types.body_content] Eliom_content.Html5.elt list -> content

module Make (C : PAGE) : sig

  (** Builds a valid html page from body content by adding headers
      for this app *)
  val make_page :
    [< Html5_types.body_content ] Eliom_content.Html5.elt list ->
    [> Html5_types.html ] Eliom_content.Html5.elt

  (** Default wrapper for service handler generating pages.
      It takes as parameter a function generating page content
      (body content) and transforms it into a function generating
      the whole page, according to the arguments given to the functor.
      Use the [predicate] function if you have something to check
      before the generation of the page. If [predicate] returns
      [false], the page will be generated using the [fallback]
      function.
      The default fallback is the error page given as parameter to the functor.
  *)
  val page :
    ?predicate:('a -> 'b -> bool Lwt.t) ->
    ?fallback:('a -> 'b -> exn ->
               [ Html5_types.body_content ] Eliom_content.Html5.elt
                 list Lwt.t) ->
    ('a -> 'b ->
     [ Html5_types.body_content ] Eliom_content.Html5.elt list Lwt.t) ->
    ('a -> 'b -> [ Html5_types.html ] Eliom_content.Html5.elt Lwt.t)


  module Opt : sig
  (** Wrapper for pages that first checks if the user is connected.
      See {!Eliom_session.Opt.connected_fun}.
  *)
    val connected_page :
      ?allow:Eba_group.t list ->
      ?deny:Eba_group.t list ->
      ?predicate:(int64 option -> 'a -> 'b -> bool Lwt.t) ->
      ?fallback:(int64 option -> 'a -> 'b -> exn ->
                 [ Html5_types.body_content ] Eliom_content.Html5.elt
                   list Lwt.t) ->
      (int64 option -> 'a -> 'b ->
       [ Html5_types.body_content ] Eliom_content.Html5.elt list Lwt.t) ->
      ('a -> 'b -> [ Html5_types.html ] Eliom_content.Html5.elt Lwt.t)

    (** More flexible wrapper than {!connected_page} for pages that
        first checks if the user is connected.
    *)
    val connected_page_full :
      ?allow:Eba_group.t list ->
      ?deny:Eba_group.t list ->
      ?predicate:(int64 option -> 'a -> 'b -> bool Lwt.t) ->
      ?fallback:(int64 option -> 'a -> 'b -> exn -> content Lwt.t) ->
      (int64 option -> 'a -> 'b -> content Lwt.t) ->
      ('a -> 'b -> [ Html5_types.html ] Eliom_content.Html5.elt Lwt.t)
  end

  (** Wrapper for pages that first checks if the user is connected.
      See {!Eliom_session.connected_fun}.
  *)
  val connected_page :
       ?allow:Eba_group.t list
    -> ?deny:Eba_group.t list
    -> ?predicate:(int64 option -> 'a -> 'b -> bool Lwt.t)
    -> ?fallback:(int64 option -> 'a -> 'b -> exn ->
                  [ Html5_types.body_content ] Eliom_content.Html5.elt list
                    Lwt.t)
    -> (int64 -> 'a -> 'b ->
        [ Html5_types.body_content ] Eliom_content.Html5.elt list Lwt.t)
    -> 'a -> 'b
    -> [ Html5_types.html ] Eliom_content.Html5.elt Lwt.t


  (** More flexible wrapper than {!connected_page} for pages that
      first checks if user is connected.
  *)
  val connected_page_full :
    ?allow:Eba_group.t list ->
    ?deny:Eba_group.t list ->
    ?predicate:(int64 option -> 'a -> 'b -> bool Lwt.t) ->
    ?fallback:(int64 option -> 'a -> 'b -> exn -> content Lwt.t) ->
    (int64 -> 'a -> 'b -> content Lwt.t) ->
    ('a -> 'b -> [ Html5_types.html ] Eliom_content.Html5.elt Lwt.t)
end
}}
