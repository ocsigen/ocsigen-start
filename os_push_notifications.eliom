module Notification =
  struct
    (* A notification is represented as a list of pair (key, value) where [key]
     * is the attribute name and [value] the attribute value in the JSON sent to
     * the server.
     *)
    type t = (string * Yojson.Safe.json) list

    let to_json t =
      `Assoc t

    (** Create an empty notification *)
    let empty () = []

    let add_raw_string key str t =
      (key, `String str) :: t

    let add_raw_json key json t =
      (key, json) :: t

    (** Add a message attribute to the notification *)
    let add_message str t = add_raw_string "message" str t

    (** Add a title attribute to the notification *)
    let add_title str t = add_raw_string "title" str t

    (** Add an image to the push notification in the notification area *)
    let add_image str t = add_raw_string "image" str t

    (** Add a soundame when the mobile receives the notification. *)
    let add_soundname str t = add_raw_string "soundname" str t

    let add_notId str t = add_raw_string "notId" str t

    let add_style str t = add_raw_string "style" str t

    let add_summary_text str t = add_raw_string "summaryText" str t

    module Action =
      struct
        type t = Yojson.Safe.json

        let to_json t = t

        let create icon title callback foreground =
        `Assoc
        [
          ("icon", `String icon) ;
          ("title", `String title) ;
          ("callback", `String callback) ;
          ("foreground", `Bool foreground)
        ]
      end

    let add_actions left right t =
      let actions_list = `List [Action.to_json left ; Action.to_json right] in
      ("actions", actions_list) :: t

    let add_led_color a r g b t =
      let json_int_list = `List [ `Int a ; `Int r ; `Int g ; `Int b ] in
      ("ledColor", json_int_list) :: t

    let add_vibration_pattern pattern t =
      ("vibrationPattern", `List (List.map (fun x -> `Int x) pattern)) ::  t

    let add_badge nb t =
      ("badge", `Int nb) :: t

    module Priority = struct
      type t = Minimum | Low | Default | High | Maximum
    end

    let add_priority priority t =
      let int_of_priority = match priority with
      | Priority.Minimum   -> -2
      | Priority.Low       -> -1
      | Priority.Default   -> 0
      | Priority.High      -> 1
      | Priority.Maximum   -> 2
      in
      ("priority", `Int int_of_priority) :: t

    let add_picture picture t = add_raw_string "picture" picture t

    let add_info info t =
      ("info", `String info) :: ("content-available", `Int 1) :: t

    module Visibility = struct
        type t = Secret | Private | Public
      end

    let add_visibility visibility t =
      let visibility_to_int = match visibility with
      | Visibility.Secret -> -1
      | Visibility.Private -> 0
      | Visibility.Public -> 1
      in
      ("visibility", `Int visibility_to_int) :: t
  end

module Options =
  struct
    type t = (string * Yojson.Safe.json) list

    let to_list t = t

    let create ids =
    [(
      "registration_ids",
      `List (List.map (fun x -> `String x) ids)
    )]

    let add_collapse_key key t =
      ("collapse_key", `String key) :: t
  end

let send server_key notification options =
  let gcm_url = "https://gcm-http.googleapis.com/gcm/send" in
  let headers =
    Http_headers.empty |>
    Http_headers.add Http_headers.authorization ("key=" ^ server_key)
  in
  let content = Yojson.Safe.to_string (
    `Assoc
    (
      ("data", Notification.to_json notification) :: (Options.to_list options)
    )
  )
  in
  (* FIXME: GCM returns a response saying if the notification has been sent *)
  ignore (Ocsigen_http_client.post_string_url
    ~headers
    ~content_type:("application", "json")
    ~content
    gcm_url
  );
  Lwt.return ()
