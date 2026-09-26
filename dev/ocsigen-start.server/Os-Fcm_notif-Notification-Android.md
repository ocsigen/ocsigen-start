# Module `Notification.Android`

```ocaml
val add_icon : string -> t -> t
```
`add_icon icon notification` indicates notification icon. Sets value to `myicon` for drawable resource `myicon`.

```ocaml
val add_tag : string -> t -> t
```
`add_tag tag notification` indicates whether each notification results in a new entry in the notification drawer on Android. If two notifications has the same tag, the last one will replace the first one. Two different tags produce two different notifications in the notification area.

```ocaml
val add_color : red:int -> green:int -> blue:int -> t -> t
```
`add_color ~red ~green ~blue notification` indicates color of the icon, expressed in \#rrggbb format.

Positive values are used modulo 256 i.e. `add_color 257 100 257 notification` is equivalent to `add_color 1 100 1`. NOTE: Don't use negative number.
