
# Module type `Os_page.PAGE`

The signature of the module to be given as parameter to the functor. It allows to personnalize your pages (CSS, JS, etc).

```ocaml
val title : string
```
`title` corresponds to the html tag \<title\>, it will be inserted on all pages.

```ocaml
val js : string list list
```
`js` corresponds to the JavaScript files to include into each page. Os will automatically preprend the suffix `"js/"` as directory.

```ocaml
val local_js : string list list
```
Use `local_js` instead of `js` for local scripts if you are building a mobile application. Os will automatically preprend the suffix `"js/"` as directory.

```ocaml
val css : string list list
```
`css` (same as `js` but for style sheet files). Os will automatically prepend the suffix `"css/"` as directory.

```ocaml
val local_css : string list list
```
Use `local_css` instead of `css` for local stylesheets if you are building a mobile application. Os will automatically prepend the suffix `"css/"` as directory.

```ocaml
val other_head : 
  unit ->
  Html_types.head_content_fun Eliom_content.Html.elt list
```
`other_head` is a list of custom elements to add in the head section. It can be used to add \<meta\> elements, for example.

```ocaml
val default_error_page : 'a -> 'b -> exn -> content Lwt.t
```
`default_error_page get_param post_param exn` is the default error page. `get_param` (resp. `post_param`) is the GET (resp. POST) parameters sent to the error page.

`exn` is the exception which must be caught when something went wrong.

```ocaml
val default_connected_error_page : 
  Os_types.User.id option ->
  'a ->
  'b ->
  exn ->
  content Lwt.t
```
`default_connected_error_page userid_o get_param post_param exn` is the default error page for connected pages.

```ocaml
val default_predicate : 'a -> 'b -> bool Lwt.t
```
`default_predicate get_param post_param` is the default predicate.

```ocaml
val default_connected_predicate : 
  Os_types.User.id option ->
  'a ->
  'b ->
  bool Lwt.t
```
`default_connected_predicate userid_o get_param post_param` is the default predicate for connected pages.
