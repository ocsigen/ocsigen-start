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

[%%shared.start]
(** Functor defining wrappers for services handlers returning pages. *)

exception Predicate_failed of exn option

type content
(** An abstract type describing the content of a page *)

val content
  :  ?html_a:Html_types.html_attrib Eliom_content.Html.attrib list
  -> ?a:Html_types.body_attrib Eliom_content.Html.attrib list
  -> ?title:string
  -> ?head:[< Html_types.head_content_fun] Eliom_content.Html.elt list
  -> [< Html_types.body_content] Eliom_content.Html.elt list
  -> content
(** Specifies a page with an optional title (with the argument [?title]), some
    optional extra metadata (with the argument [?head]) and a given body.

    [?html_a] (resp. [?a]) allows to set attributes to the html (resp. body)
    tag.
 *)

(** The signature of the module to be given as parameter to the functor.
    It allows to personnalize your pages (CSS, JS, etc).
*)
module type PAGE = sig
  val title : string
  (** [title] corresponds to the html tag <title>, it will be inserted on all
      pages.  *)

  val js : string list list
  (** [js] corresponds to the JavaScript files to include into each page.
      Os will automatically preprend the suffix ["js/"] as directory.  *)

  val local_js : string list list
  (** Use [local_js] instead of [js] for local scripts if you are building
      a mobile application.
      Os will automatically preprend the suffix ["js/"] as directory.  *)

  val css : string list list
  (** [css] (same as [js] but for style sheet files).
      Os will automatically prepend the suffix ["css/"] as directory.  *)

  val local_css : string list list
  (** Use [local_css] instead of [css] for local stylesheets if you are building
      a mobile application.
      Os will automatically prepend the suffix ["css/"] as directory.  *)

  val other_head : Html_types.head_content_fun Eliom_content.Html.elt list
  (** [other_head] is a list of custom elements to add in the head section.
      It can be used to add <meta> elements, for example. *)

  val default_error_page : 'a -> 'b -> exn -> content Lwt.t
  (** [default_error_page get_param post_param exn] is the default error page.
      [get_param] (resp. [post_param]) is the GET (resp. POST) parameters sent
      to the error page.

      [exn] is the exception which must be caught when something went wrong.
   *)

  val default_connected_error_page
    :  Os_types.User.id option
    -> 'a
    -> 'b
    -> exn
    -> content Lwt.t
  (** [default_connected_error_page userid_o get_param post_param exn] is the
      default error page for connected pages.
   *)

  val default_predicate : 'a -> 'b -> bool Lwt.t
  (** [default_predicate get_param post_param] is the default predicate. *)

  val default_connected_predicate
    :  Os_types.User.id option
    -> 'a
    -> 'b
    -> bool Lwt.t
  (** [default_connected_predicate userid_o get_param post_param] is the default
      predicate for connected pages.
   *)
end

module Default_config : PAGE
(** A default configuration for pages.
    - no CSS and JS files are included.
    - no meta data are added in head
    - error page prints debug information about the exception.
    - a div is returned in case of an error with class ["errormsg"] containing a
    h2 with value ["Error"] and a paragraph if the exception is
    {!Os_session.Not_connected}.
 *)

module Make (_ : PAGE) : sig
  val make_page : content -> [> Html_types.html] Eliom_content.Html.elt
  (** Builds a valid html page from body content by adding headers
      for this app *)

  val page
    :  ?predicate:('a -> 'b -> bool Lwt.t)
    -> ?fallback:('a -> 'b -> exn -> content Lwt.t)
    -> ('a -> 'b -> content Lwt.t)
    -> 'a
    -> 'b
    -> Html_types.html Eliom_content.Html.elt Lwt.t
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

  module Opt : sig
    val connected_page
      :  ?allow:Os_types.Group.t list
      -> ?deny:Os_types.Group.t list
      -> ?predicate:(Os_types.User.id option -> 'a -> 'b -> bool Lwt.t)
      -> ?fallback:(Os_types.User.id option -> 'a -> 'b -> exn -> content Lwt.t)
      -> (Os_types.User.id option -> 'a -> 'b -> content Lwt.t)
      -> 'a
      -> 'b
      -> Html_types.html Eliom_content.Html.elt Lwt.t
    (** Wrapper for pages that first checks if the user is connected.
      See {!Os_session.Opt.connected_fun}.
  *)
  end

  val connected_page
    :  ?allow:Os_types.Group.t list
    -> ?deny:Os_types.Group.t list
    -> ?predicate:(Os_types.User.id option -> 'a -> 'b -> bool Lwt.t)
    -> ?fallback:(Os_types.User.id option -> 'a -> 'b -> exn -> content Lwt.t)
    -> (Os_types.User.id -> 'a -> 'b -> content Lwt.t)
    -> 'a
    -> 'b
    -> Html_types.html Eliom_content.Html.elt Lwt.t
  (** Wrapper for pages that first checks if the user is connected.
      See {!Os_session.connected_fun}.
  *)
end
