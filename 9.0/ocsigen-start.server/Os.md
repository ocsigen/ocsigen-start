# Module `Os`

```ocaml
module Comet : sig ... end
```
This module provides function to monitor communications between the server clients. It's only defined for internal uses so not a lot of things are exported.

```ocaml
module Connect_phone : sig ... end
```
```ocaml
module Core_db : sig ... end
```
This module defines low level functions for database requests.

```ocaml
module Current_user : sig ... end
```
This module provides functions and types to manage the current user.

```ocaml
module Date : sig ... end
```
Time zone and date management for Web applications.

```ocaml
module Db : sig ... end
```
This module defines low level functions for database requests.

```ocaml
module Email : sig ... end
```
Basic module for sending e-mail messages to users, using some local sendmail program.

```ocaml
module Fcm_notif : sig ... end
```
Send push notifications to Android and iOS mobile devices.

```ocaml
module Group : sig ... end
```
Groups of users. Groups are sets of users. Groups and group members are saved in database. Groups are used by OS for example to restrict access to pages or server functions.

```ocaml
module Handlers : sig ... end
```
This module contains pre-defined handlers for connect, disconnect, sign up, add a new email, etc. Each handler has a corresponding service in [`Services`](./Os-Services.md).

```ocaml
module Icons : sig ... end
```
The icons used internally by Ocsigen Start's library. Customize them with your own icons by calling module `Register`.

```ocaml
module Lib : sig ... end
```
This module aims to provide common utilities functions.

```ocaml
module Msg : sig ... end
```
```ocaml
module Notif : sig ... end
```
Server to client notifications.

```ocaml
module Page : sig ... end
```
```ocaml
module Platform : sig ... end
```
About device platform.

```ocaml
module Request_cache : sig ... end
```
Caching request data to avoid doing the same computation several times during the same request.

```ocaml
module Services : sig ... end
```
```ocaml
module Session : sig ... end
```
Connection and disconnection of users, restrict access to services or server functions, define actions to be executed at some points of the session.

```ocaml
module Tips : sig ... end
```
Tips for new users and new features.

```ocaml
module Types : sig ... end
```
Data types

```ocaml
module Uploader : sig ... end
```
This module defines functions to manipulate images to be uploaded.

```ocaml
module User : sig ... end
```
This module provides functions and types about users.

```ocaml
module User_proxy : sig ... end
```
This module implements a cache of user using [`Eliom.Cscache`](./../../eliom/eliom.server/Eliom-Cscache.md) which allows to keep synchronized the cache between the client and the server. Even if there is a cache implemented in [`User`](./Os-User.md) to avoid to do database requests, this last one is implementing only server side. Same for [`Request_cache`](./Os-Request_cache.md) which is also only server-side.

```ocaml
module User_view : sig ... end
```
This module defines functions to create password forms, connection forms, settings buttons and other common contents arising in applications. As Eliom.Content.Html.F is opened by default, if the module D is not explicitly used, HTML tags will be functional.
