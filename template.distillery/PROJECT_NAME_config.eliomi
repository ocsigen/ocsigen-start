val app_name : string ref

val css_name : string ref

val avatar_dir : string list ref

val os_db_host : string option ref

val os_db_port : int option ref

val os_db_user : string option ref

val os_db_password : string option ref

val os_db_database : string option ref

val os_db_unix_domain_socket_dir : string option ref

val app : Ocsigen_extensions.Configuration.element

val avatars : Ocsigen_extensions.Configuration.element

val os_db : Ocsigen_extensions.Configuration.element
