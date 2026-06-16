
# Module `Os_tips`

Tips for new users and new features.

```ocaml
val bubble : 
  ?a:[< Html_types.div_attrib Class ] Eliom_content.Html.D.attrib list ->
  ?recipient:[> `All | `Connected | `Not_connected ] ->
  ?arrow:
    [ `left of int | `right of int | `top of int | `bottom of int ]
      Eliom_client_value.t ->
  ?top:int Eliom_client_value.t ->
  ?left:int Eliom_client_value.t ->
  ?right:int Eliom_client_value.t ->
  ?bottom:int Eliom_client_value.t ->
  ?height:int Eliom_client_value.t ->
  ?width:int Eliom_client_value.t ->
  ?parent_node:[< `Body | Html_types.body_content ] Eliom_content.Html.elt ->
  ?delay:float ->
  ?onclose:(unit -> unit Lwt.t) Eliom_client_value.t ->
  name:string ->
  content:
    ((unit -> unit Lwt.t) ->
      Html_types.div_content Eliom_content.Html.elt list Lwt.t)
      Eliom_client_value.t ->
  unit ->
  unit Lwt.t
```
Display tips in pages, as a speech bubble.

One tip is displayed at a time.

Tips can be inserted in page using function `display`, that may be called anywhere during the generation of a page. The tip will be actually sent and displayed on client side only if the user has not already seen it.

- `~name` is a unique name you must choose for your tip
- `?arrow` is the position of the arrow if you want one
- `?top`, `?bottom`, `?left`, `?right`, `?width`, `?right` correspond to the eponymous CSS properties.
- `~content` takes the function closing the tip as parameter and return the content of the tip div.
- `?recipient` makes it possible to decide whether the tip will be displayed for connected users only, non-connected users only, or all (default). Tips for non-connected users will reappear every time the session is closed.
- `?delay` adds a delay before displaying the tip (in seconds)
```ocaml
val block : 
  ?a:[< Html_types.div_attrib Class ] Eliom_content.Html.D.attrib list ->
  ?recipient:[> `All | `Connected | `Not_connected ] ->
  ?onclose:(unit -> unit Lwt.t) Eliom_client_value.t ->
  name:string ->
  content:
    ((unit -> unit Lwt.t) Eliom_client_value.t ->
      Html_types.div_content Eliom_content.Html.elt list Lwt.t) ->
  unit ->
  [> `Div ] Eliom_content.Html.elt option Lwt.t
```
Return a box containing a tip, to be inserted where you want in a page. The box contains a close button. Once it is closed, it is never displayed again for this user. In that case the function returns `None`.

```ocaml
val reset_tips : unit -> unit Lwt.t
```
Call this function to reset tips for current user. Tips will be shown again from the beginning.

```ocaml
val set_tip_seen : string -> unit Lwt.t
```
Call this function to mark a tip as "already seen" by current user. This is done automatically when a tip is closed.

```ocaml
val unset_tip_seen : string -> unit Lwt.t
```
Counterpart of set\_tip\_seen. Does not fail if the tip has not been seen yet

```ocaml
val tip_seen : string -> bool Lwt.t
```
Returns whether a tip has been seen or not.

```ocaml
val reset_tips_service : 
  (unit,
    unit,
    Eliom_service.post,
    Eliom_service.non_att,
    Eliom_service.co,
    Eliom_service.non_ext,
    Eliom_service.reg,
    [ `WithoutSuffix ],
    unit,
    unit,
    Eliom_service.non_ocaml)
    Eliom_service.t
```
A non-attached service that will reset tips. Call it with `Eliom_client.exit_to` to restart the application and see tips again.
