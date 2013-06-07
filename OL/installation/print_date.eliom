(* Copyright Séverine Maingaud *)
{shared{
open CalendarLib

let smart_date date today =
  let p = Date.Period.safe_nb_days (Date.sub date today) in
  if p  = 0 then "Today" else
    if p = 1 || p = -1
    then "Yesterday"
    else let format =
           if (Date.year date = Date.year today)
           then "%A %d %B" else "%A %d %B %Y"
         in
         Printer.Date.sprint format date



let hours_minutes t =
  let t = Calendar.to_time t in
  Printer.Time.sprint "%H:%M" t

}}
