(* Copyright Séverine Maingaud *)

(* This file defines icons for web application using
   Awesome font family. *)

{shared{
open Eliom_content.Html5.F

let user = i ~a:[a_class ["icon-user"]] []
let plus = i ~a:[a_class ["icon-plus"]] []
let envelope = i ~a:[a_class ["icon-envelope" ;
                              "icon-large"]] []
let logout = i ~a:[a_class ["icon-logout"]] []
let add_atts = [i ~a:[a_class ["icon-user"]] [];
                i ~a:[a_class ["icon-plus"]] []]
let remove = i ~a:[a_class ["icon-remove"]] []
let ok_circle = i ~a:[a_class ["icon-ok-circle"]] []
let remove_circle = i ~a:[a_class ["icon-remove-circle"]] []
}}
