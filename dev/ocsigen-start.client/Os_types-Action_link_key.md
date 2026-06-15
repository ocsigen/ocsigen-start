
# Module `Os_types.Action_link_key`

```ocaml
type info = {
  userid : User.id;
  email : string;
  validity : int64;
  expiry : CalendarLib.Calendar.t option;
  autoconnect : bool;
  action : [ `AccountActivation | `PasswordReset | `Custom of string ];
  data : string;
}
```
Type representing information about the action link key
