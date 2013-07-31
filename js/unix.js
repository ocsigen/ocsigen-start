function unix_inet_addr_of_string () {return 0;}
function unix_time () {return 0;}
function unix_gmtime () {return 0;}
function caml_ml_output_char () {return 0;}
function caml_get_exception_backtrace () {return 0;}


function unix_gettimeofday () {
  return (new Date()).getTime() / 1000;
}

function unix_gmtime (t) {
  var d = new Date (t * 1000);
  var januaryfirst = new Date(d.getUTCFullYear(), 0, 1);
  var doy = Math.floor((d - januaryfirst) / 86400000);
  return [0, d.getUTCSeconds(), d.getUTCMinutes(), d.getUTCHours(),
          d.getUTCDate(), d.getUTCMonth(), d.getUTCFullYear() - 1900,
          d.getUTCDay(), doy,
          false /* for UTC daylight savings time is false */]
}

function unix_localtime (t) {
var d = new Date (t * 1000);
var januaryfirst = new Date(d.getFullYear(), 0, 1);
var doy = Math.floor((d - januaryfirst) / 86400000);
return [0, d.getSeconds(), d.getMinutes(), d.getHours(),
d.getDate(), d.getMonth(), d.getFullYear() - 1900,
d.getDay(), doy,
false /* daylight savings time  field. Not implemented: not used. */]
}
