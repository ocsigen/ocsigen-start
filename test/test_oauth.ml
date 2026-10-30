(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright (C) Be Sport, Tarides.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

(* Tests of the ID token checks behind Os.Oauth, without network.

   Whatever [Core_oauth.validate] accepts becomes a logged-in user. Each of
   its checks (signature, key id, algorithm, issuer, audience, expiry) is the
   only thing standing between a forged token and an account, so each is
   tested on its own, by changing one thing at a time.

   The key pairs are fixed rather than generated: the tests need no entropy
   source and fail for one reason only. They are 2048-bit test keys, valid
   nowhere. *)

let e = Z.of_int 65537

let rsa_key ~p ~q =
  match
    Mirage_crypto_pk.Rsa.priv_of_primes ~e ~p:(Z.of_string p) ~q:(Z.of_string q)
  with
  | Ok key -> key
  | Error (`Msg msg) -> failwith ("test key: " ^ msg)

let priv =
  rsa_key
    ~p:
      "0xEFADA2A0D87C4CEC2C8D543A8381474FA6760B1A2F43CD792DB602C8901626E39E511F633604BA5DBCC2BD9FBA7C813BCC06DA98B889BEBB6168CD019960CE206CC98868986FBA1FDF6E101B5BCC4CAA7DFC54EA137E2749DC0BB6CBF1332DD52E1DE880BCDDB00B95E9228455E90847A4FD96DD5E0711B806C5EA073C0D2345"
    ~q:
      "0xE1889E41572671C4181FD9DEF7956CFE4C47E448D3AAFB6A8B9310D603AED208D9F085F804A07E463692D6BAE0DD2C478DFE63D32F625AFF53AAA2CA94F2ABE0EC2C78D6B8D808A01B42F4B884F38497294470CCB5A42978F612060AC02E1BA731499680B34556476FE162EC5842CC6C91A2F34CF9597417B4D6222ED07B3137"

(* An unrelated key, unknown to the verifier. *)
let other_priv =
  rsa_key
    ~p:
      "0xC4AD039A5C886C3D79C44BC98EF671B8071827FA4985EE92590EA9958277CD1A577E3569A54C3CD0B0951DA75F415812402CE2E0F79D9150F386BC36E10C075320536A0A2FED950F6C8C413987A9C9C1FCA8BDC344572F0E0A8ED69CDEA3E81F7D172395C8A4E31B07EB978B78A5FB4EA894F18D9A303EABF3E2D29F3A3DA36D"
    ~q:
      "0xD34DB6DDDD9DDD326C8E16BC43EC8F30617EFC62F2449AF9D3C233ED27C24DA7910827D16AEB6F59A29CC27871909DB1359567C986CF5E7040606818B71B78AFC7A01C8F3FF3FE9293BF174CB4A2D23F287E631649BFAEFEFF77163805B6AF12F1C17DA6FCAFF83AC3999419A4B37DF91F9D3CD108A90E84BDEDD464F163D679"

let kid = "test-key-1"
let issuer = "https://accounts.google.com"
let audience = "1234.apps.googleusercontent.com"
let now = 1_800_000_000.
let in_an_hour = `Int 1_800_003_600

(* The JWKS document the provider would publish, as text. *)
let jwks_text jwks = Jose.Jwks.to_string {Jose.Jwks.keys = jwks}

let rsa_jwk ?(kid = kid) priv =
  Jose.Jwk.Rsa_pub
    { Jose.Jwk.alg = Some `RS256
    ; kty = `RSA
    ; use = Some `Sig
    ; kid = Some kid
    ; key = Mirage_crypto_pk.Rsa.pub_of_priv priv }

let keys_of jwks =
  match Core_oauth.keys_of_string (jwks_text jwks) with
  | Ok keys -> keys
  | Error msg -> failwith ("test key set: " ^ msg)

let keys = keys_of [rsa_jwk priv]
let b64 s = Base64.encode_string ~pad:false ~alphabet:Base64.uri_safe_alphabet s
let segment json = b64 (Yojson.Safe.to_string json)

(* Signs the two segments verbatim, as an issuer does: the signature covers
   the base64url text, not the JSON it encodes. *)
let sign ?(key = priv) header payload =
  let signed = header ^ "." ^ payload in
  let signature =
    Mirage_crypto_pk.Rsa.PKCS1.sign ~mask:`No ~hash:`SHA256 ~key
      (`Message signed)
  in
  signed ^ "." ^ b64 signature

let header ?(alg = "RS256") ?(kid = Some kid) () =
  segment
    (`Assoc
        (("alg", `String alg)
        :: Option.fold ~none:[] ~some:(fun kid -> ["kid", `String kid]) kid))

let claims
      ?(iss = `String issuer)
      ?(aud = `String audience)
      ?(exp = in_an_hour)
      ()
  =
  `Assoc
    [ "iss", iss
    ; "aud", aud
    ; "exp", exp
    ; "sub", `String "10769150350006150715113082367"
    ; "email", `String "user@example.org" ]

let token ?key ?alg ?kid ?iss ?aud ?exp () =
  sign ?key (header ?alg ?kid ()) (segment (claims ?iss ?aud ?exp ()))

let validate ?(keys = keys) ?(issuers = [issuer]) ?(audiences = [audience]) t =
  Core_oauth.validate ~now ~keys ~allowed_issuers:issuers
    ~allowed_audiences:audiences t

let error = Alcotest.testable Core_oauth.pp_error ( = )

let accepted ?keys ?issuers ?audiences msg t =
  match validate ?keys ?issuers ?audiences t with
  | Ok claims ->
      Alcotest.(check string)
        (msg ^ ": claims returned")
        "user@example.org"
        Yojson.Safe.Util.(to_string (member "email" claims))
  | Error e -> Alcotest.failf "%s: %a" msg Core_oauth.pp_error e

let refused ?keys ?issuers ?audiences expected msg t =
  match validate ?keys ?issuers ?audiences t with
  | Ok _ -> Alcotest.failf "%s: token accepted" msg
  | Error e -> Alcotest.check error msg expected e

(* The message of [Malformed] and [Rejected] is for the logs only. *)
let malformed ?keys msg t =
  match validate ?keys t with
  | Error (Core_oauth.Malformed _) -> ()
  | Ok _ -> Alcotest.failf "%s: token accepted" msg
  | Error e -> Alcotest.failf "%s: %a" msg Core_oauth.pp_error e

let rejected ?keys ?issuers ?audiences msg t =
  match validate ?keys ?issuers ?audiences t with
  | Error (Core_oauth.Rejected _) -> ()
  | Ok _ -> Alcotest.failf "%s: token accepted" msg
  | Error e -> Alcotest.failf "%s: %a" msg Core_oauth.pp_error e

let test_valid () =
  accepted "a well-formed token" (token ());
  accepted "an audience among several"
    ~audiences:["5678.apps.googleusercontent.com"; audience]
    (token ());
  accepted "an issuer among several"
    ~issuers:["accounts.google.com"; issuer]
    (token ());
  accepted "an expiry as a float" (token ~exp:(`Float (now +. 60.)) ());
  accepted "the right key among several"
    ~keys:(keys_of [rsa_jwk ~kid:"other" other_priv; rsa_jwk priv])
    (token ())

let test_signature () =
  rejected "signed by another key with the same key id"
    (token ~key:other_priv ());
  let t = token () in
  let i = String.rindex t '.' + 1 in
  let flipped =
    String.mapi (fun j c -> if j = i then if c = 'A' then 'B' else 'A' else c) t
  in
  rejected "tampered signature" flipped;
  rejected "empty signature" (String.sub t 0 i);
  malformed "signature dropped" (String.sub t 0 (i - 1))

let test_payload_tampering () =
  match String.split_on_char '.' (token ()) with
  | [h; _; s] ->
      let forged =
        segment
          (`Assoc
              [ "iss", `String issuer
              ; "aud", `String audience
              ; "exp", in_an_hour
              ; "email", `String "admin@example.org" ])
      in
      rejected "claims swapped under a valid signature"
        (String.concat "." [h; forged; s])
  | _ -> Alcotest.fail "the token should have three segments"

let test_key_id () =
  refused (Core_oauth.Unknown_key "rotated-away") "unknown key id"
    (token ~kid:(Some "rotated-away") ());
  refused ~keys:(keys_of []) (Core_oauth.Unknown_key kid) "empty key set"
    (token ());
  malformed "no key id" (token ~kid:None ())

let test_algorithm () =
  rejected "alg: none" (token ~alg:"none" ());
  rejected "alg: HS256" (token ~alg:"HS256" ());
  rejected "alg: RS512" (token ~alg:"RS512" ());
  (* A symmetric key published under the key id must not be used to check
     the token, even when the header asks for RS256. *)
  let oct =
    Jose.Jwk.Oct
      { Jose.Jwk.alg = Some `HS256
      ; kty = `oct
      ; use = Some `Sig
      ; kid = Some kid
      ; key = b64 "a shared secret" }
  in
  rejected ~keys:(keys_of [oct]) "key of another type" (token ())

let test_issuer_and_audience () =
  rejected "issuer not on the list"
    (token ~iss:(`String "https://evil.example") ());
  rejected "audience of another application"
    (token ~aud:(`String "9999.apps.googleusercontent.com") ());
  rejected "issuer as a prefix"
    (token ~iss:(`String (issuer ^ ".evil.example")) ());
  rejected "audience as a suffix" (token ~aud:(`String ("x" ^ audience)) ());
  rejected ~issuers:[] "no allowed issuer" (token ());
  rejected ~audiences:[] "no allowed audience" (token ());
  accepted "audience array" (token ~aud:(`List [`String audience]) ());
  rejected "audience array with an untrusted audience"
    (token ~aud:(`List [`String audience; `String "9999"]) ());
  rejected "empty audience array" (token ~aud:(`List []) ())

let test_expiry () =
  rejected "expired an hour ago" (token ~exp:(`Int 1_799_996_400) ());
  rejected "expired a second ago" (token ~exp:(`Int 1_799_999_999) ());
  rejected "expiring now" (token ~exp:(`Int 1_800_000_000) ());
  accepted "still valid for a second" (token ~exp:(`Int 1_800_000_001) ())

let test_missing_claims () =
  let signed claims = sign (header ()) (segment (`Assoc claims)) in
  let iss = "iss", `String issuer in
  let aud = "aud", `String audience in
  let exp = "exp", in_an_hour in
  rejected "no claims at all" (signed []);
  rejected "no issuer" (signed [aud; exp]);
  rejected "no audience" (signed [iss; exp]);
  rejected "no expiry" (signed [iss; aud]);
  rejected "expiry as a string" (signed [iss; aud; "exp", `String "9999999999"]);
  rejected "issuer as a number" (signed ["iss", `Int 1; aud; exp]);
  rejected "payload not an object"
    (sign (header ()) (segment (`List [`String issuer])))

let test_malformed () =
  malformed "empty string" "";
  malformed "no dots" "not-a-token";
  malformed "two segments" "aaa.bbb";
  malformed "four segments" "aaa.bbb.ccc.ddd";
  malformed "segments are not base64url" "!!!.???.***";
  malformed "header is not JSON" (b64 "not json" ^ ".e30.c2ln");
  malformed "header without alg" (segment (`Assoc []) ^ ".e30.c2ln");
  malformed "payload is not JSON" (sign (header ()) (b64 "not json"));
  malformed "JSON serialization"
    (Printf.sprintf {|{"payload":"e30","protected":"%s","signature":"c2ln"}|}
       (header ()))

let test_keys_of_string () =
  let is_error msg s =
    Alcotest.(check bool)
      msg true
      (Result.is_error (Core_oauth.keys_of_string s))
  in
  is_error "not JSON" "{";
  is_error "not an object" "[]";
  is_error "no keys field" "{}";
  is_error "keys not an array" {|{"keys": {}}|};
  (* A key that cannot be decoded is skipped, the others are kept. *)
  let good = Jose.Jwk.to_pub_json (rsa_jwk priv) in
  let text =
    Yojson.Safe.to_string
      (`Assoc ["keys", `List [`Assoc ["kid", `String "no-kty"]; `Int 3; good]])
  in
  match Core_oauth.keys_of_string text with
  | Ok keys -> accepted ~keys "key set with undecodable keys" (token ())
  | Error msg -> Alcotest.failf "key set refused: %s" msg

let test_max_age () =
  let check msg expected s =
    Alcotest.(check (option int)) msg expected (Core_oauth.max_age s)
  in
  check "Google's header" (Some 19970)
    "public, max-age=19970, must-revalidate, no-transform";
  check "alone" (Some 60) "max-age=60";
  check "case and spaces" (Some 5) " Max-Age = 5 ";
  check "absent" None "no-cache";
  check "empty" None "";
  check "s-maxage is another directive" None "s-maxage=10";
  check "negative" None "max-age=-1";
  check "not a number" None "max-age=abc";
  check "no value" None "max-age="

let () =
  Alcotest.run "oauth"
    [ ( "validate"
      , [ Alcotest.test_case "valid token" `Quick test_valid
        ; Alcotest.test_case "signature" `Quick test_signature
        ; Alcotest.test_case "payload tampering" `Quick test_payload_tampering
        ; Alcotest.test_case "key id" `Quick test_key_id
        ; Alcotest.test_case "algorithm" `Quick test_algorithm
        ; Alcotest.test_case "issuer and audience" `Quick
            test_issuer_and_audience
        ; Alcotest.test_case "expiry" `Quick test_expiry
        ; Alcotest.test_case "missing claims" `Quick test_missing_claims
        ; Alcotest.test_case "malformed" `Quick test_malformed ] )
    ; ( "keys"
      , [ Alcotest.test_case "key set" `Quick test_keys_of_string
        ; Alcotest.test_case "max-age" `Quick test_max_age ] ) ]
