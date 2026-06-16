
# Module `Os_types`

Data types

This module defines types used in ocsigen-start in multiple files. It gives a more readable interface (for example by using `Os_types.User.id` instead of `int64`). Put all most used types in this file avoids to have dependencies between different modules for only one type. \*

Types related to users.

```ocaml
module User : sig ... end
```
Types related to action link keys

```ocaml
module Action_link_key : sig ... end
```
```ocaml
module Group : sig ... end
```