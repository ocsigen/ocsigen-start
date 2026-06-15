
# Module `Os_page`

```ocaml
exception Predicate_failed of exn option
```
```ocaml
type content
```
An abstract type describing the content of a page

```ocaml
val content : 
  ?html_a:Html_types.html_attrib Eliom_content.Html.attrib list ->
  ?a:Html_types.body_attrib Eliom_content.Html.attrib list ->
  ?title:string ->
  ?head:[< Html_types.head_content_fun ] Eliom_content.Html.elt list ->
  [< Html_types.body_content ] Eliom_content.Html.elt list ->
  content
```
Specifies a page with an optional title (with the argument `?title`), some optional extra metadata (with the argument `?head`) and a given body.

`?html_a` (resp. `?a`) allows to set attributes to the html (resp. body) tag.

```ocaml
module type PAGE = sig ... end
```
The signature of the module to be given as parameter to the functor. It allows to personnalize your pages (CSS, JS, etc).

```ocaml
module Default_config : PAGE
```
A default configuration for pages.

```ocaml
module Make (_ : PAGE) : sig ... end
```