open ServiceWorker

let cacheName = Js.string "%%%PROJECT_NAME%%%-app-shell-1.0"

let filesToCache =[|
  "/";
  "/css/%%%PROJECT_NAME%%%.css";
  "/%%%PROJECT_NAME%%%.js"
|]
  |> Array.map Js.string
  |> Js.array

let install_handler () = 
  let self = get_self () in
  Dom_html.handler (fun (ev:installEvent Js.t) -> 
    Firebug.console##log 
      (Js.string "[ServiceWorker] Installed");
    ev##waitUntil (
      let p = self##.caches##_open cacheName in
      Promise._then p 
        (fun cache -> 
           Firebug.console##log (Js.string  "[ServiceWorker] Catch app shell");
           cache##addAll_withUrl filesToCache)
    );
    Js._false)

let activate_handler () =
  let self = get_self () in
  Dom_html.handler (fun (ev:activateEvent Js.t) -> 
    Firebug.console##log (Js.string "[ServiceWorker] Activate");
    ignore @@ self##.clients##claim;
    Js._false)

let fetch_handler () =
  let self = get_self () in
  Dom_html.handler (fun (ev:fetchEvent Js.t) ->
    Firebug.console##log 
      ((Js.string "[ServiceWorker] Fetch ")##concat (ev##.request##.url));
    ev##respondWith(self##fetch ev##.request);
    Js._false)

let () = 
  ignore @@ addInstallListener (install_handler ()) ;
  ignore @@ addActivateListener (activate_handler ());
  ignore @@ addFetchListener (fetch_handler());