# Library `ocsigen-start.server`

[`Os_comet`](./Os_comet.md) This module provides function to monitor communications between the server clients. It's only defined for internal uses so not a lot of things are exported.
[`Os_connect_phone`](./Os_connect_phone.md)
[`Os_core_db`](./Os_core_db.md) This module defines low level functions for database requests.
[`Os_current_user`](./Os_current_user.md) This module provides functions and types to manage the current user.
[`Os_date`](./Os_date.md) Time zone and date management for Web applications.
[`Os_db`](./Os_db.md) This module defines low level functions for database requests.
[`Os_email`](./Os_email.md) Basic module for sending e-mail messages to users, using some local sendmail program.
[`Os_fcm_notif`](./Os_fcm_notif.md) Send push notifications to Android and iOS mobile devices.
[`Os_group`](./Os_group.md) Groups of users. Groups are sets of users. Groups and group members are saved in database. Groups are used by OS for example to restrict access to pages or server functions.
[`Os_handlers`](./Os_handlers.md) This module contains pre-defined handlers for connect, disconnect, sign up, add a new email, etc. Each handler has a corresponding service in Os\_services.
[`Os_icons`](./Os_icons.md) The icons used internally by Ocsigen Start's library. Customize them with your own icons by calling module Register.
[`Os_lib`](./Os_lib.md) This module aims to provide common utilities functions.
[`Os_msg`](./Os_msg.md)
[`Os_notif`](./Os_notif.md) Server to client notifications.
[`Os_page`](./Os_page.md)
[`Os_platform`](./Os_platform.md) About device platform.
[`Os_request_cache`](./Os_request_cache.md) Caching request data to avoid doing the same computation several times during the same request.
[`Os_services`](./Os_services.md)
[`Os_session`](./Os_session.md) Connection and disconnection of users, restrict access to services or server functions, define actions to be executed at some points of the session.
[`Os_tips`](./Os_tips.md) Tips for new users and new features.
[`Os_types`](./Os_types.md) Data types
[`Os_uploader`](./Os_uploader.md) This module defines functions to manipulate images to be uploaded.
[`Os_user`](./Os_user.md) This module provides functions and types about users.
[`Os_user_proxy`](./Os_user_proxy.md) This module implements a cache of user using Eliom\_cscache which allows to keep synchronized the cache between the client and the server. Even if there is a cache implemented in Os\_user to avoid to do database requests, this last one is implementing only server side. Same for Os\_request\_cache which is also only server-side.
[`Os_user_view`](./Os_user_view.md) This module defines functions to create password forms, connection forms, settings buttons and other common contents arising in applications. As Eliom\_content.Html.F is opened by default, if the module D is not explicitly used, HTML tags will be functional.
