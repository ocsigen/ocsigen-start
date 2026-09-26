// WebAssembly loader for Ocsigen applications
// Detects WASM support and loads the appropriate version

(function() {
  'use strict';
  
  // Disable the automatic Eliom script if WASM loader is active
  // This runs immediately to prevent script execution
  if (window.__ELIOM_USE_WASM__) {
    // Override document.write to intercept any automatic script injection
    var original_write = document.write;
    document.write = function(content) {
      // Block caml_p scripts
      if (content.indexOf('caml_p') === -1 || content.indexOf('class="caml_p"') === -1) {
        original_write.call(document, content);
      }
    };
    
    // Also disable any existing caml_p scripts (for scripts already in DOM)
    setTimeout(function() {
      var scripts = document.getElementsByTagName('script');
      for (var i = 0; i < scripts.length; i++) {
        if (scripts[i].className && scripts[i].className.indexOf('caml_p') !== -1 && 
            scripts[i] !== document.currentScript) {
          scripts[i].type = 'text/plain';
          if (scripts[i].parentNode) {
            scripts[i].parentNode.removeChild(scripts[i]);
          }
        }
      }
    }, 0);
  }
  
  // Check WebAssembly support
  function supportsWasm() {
    try {
      if (typeof WebAssembly === "object" && typeof WebAssembly.instantiate === "function") {
        var module = new WebAssembly.Module(Uint8Array.of(0x0, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00));
        if (module instanceof WebAssembly.Module) {
          return new WebAssembly.Instance(module) instanceof WebAssembly.Instance;
        }
      }
    } catch (e) {}
    return false;
  }

  // Get data attributes
  var currentScript = document.currentScript;
  if (!currentScript) return;
  
  var jsPath = currentScript.getAttribute('data-js');
  var wasmPath = currentScript.getAttribute('data-wasm');
  
  // Load the appropriate script
  var scriptToLoad = (supportsWasm() && wasmPath) ? wasmPath : jsPath;
  
  if (scriptToLoad) {
    console.log('Loading:', supportsWasm() ? 'WebAssembly' : 'JavaScript', 'version');
    var script = document.createElement('script');
    script.src = scriptToLoad;
    script.async = false;
    document.head.appendChild(script);
  }
})();
