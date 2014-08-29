(* Copyright Séverine Maingaud *)

(* This file defines icons for web application using
   Awesome font family. *)

{shared{
open Eliom_content.Html5.F

let user = i ~a:[a_class ["fa"; "fa-user"; "fa-fw"]] []
let plus = i ~a:[a_class ["fa"; "fa-plus"; "fa-fw"]] []
let envelope = i ~a:[a_class ["fa"; "fa-envelope"; "fa-fw" ]] []
let logout = i ~a:[a_class ["fa"; "fa-logout"; "fa-fw"]] []
let add_atts = [i ~a:[a_class ["fa"; "fa-user"]] [];
                i ~a:[a_class ["fa"; "fa-plus"]] []]
let remove = i ~a:[a_class ["fa"; "fa-times"; "fa-fw"]] []
let ok_circle = i ~a:[a_class ["fa"; "fa-check-circle"; "fa-fw"]] []
let remove_circle = i ~a:[a_class ["fa"; "fa-times-circle"; "fa-fw"]] []
let upload = i ~a:[a_class ["fa"; "fa-cloud-upload"; "fa-fw"]] []
let discussion = i ~a:[a_class ["fa"; "fa-comments"; "fa-fw"]] []
let spinner = i ~a:[a_class ["fa"; "fa-spinner"; "fa-spin"; "fa-fw"]] []
let file = i ~a:[a_class ["fa"; "fa-file"; "fa-fw"]] []
let download = i ~a:[a_class ["fa"; "fa-cloud-download"; "fa-fw"]] []
let share = i ~a:[a_class ["fa"; "fa-share"; "fa-fw"]] []
let app = i ~a:[a_class ["fa"; "fa-edit"; "fa-fw"]] []
let textedit = app
let shutdown = i ~a:[a_class ["fa"; "fa-sign-out"; "fa-fw"]] []

}}
