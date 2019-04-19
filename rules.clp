
(defrule parse_data_file
)

; Ask the user if they have a budget
(defrule price_pref
	initial-fact
	=>
	(printout t "Do you have lower and/or upper limit on your budget?  If so, respond with yes and a lower limit and upper limit, or just respond with no: " crlf)
	(assert (price_pref (read)))
)

(defrule parse_price_pref 
	?p <- (price_pref ?ans $?lower $?higher)
	(and (exists $?lower) (exists $?higher))
	=>
	(retract ?p)
	(assert (price_lower ?lower))
	(assert (price_higher ?higher))
)

; Ask the user if they have any cpu preferences
(defrule cpu_pref
	initial-fact
	=>
)

; Ask the user if they have any gpu preferences
(defrule gpu_pref
	initial-fact
	=>
)

; Ask the user if they have any ram preferences
(defrule ram_pref
	initial-fact
	=>
)

; Ask the user what parts they already have and plan to use in the new build.  For example, they may already have a hard drive or power supply, 
(defrule current_parts
	initial-fact
	=>
	(printout t "What parts do you already have and want to use in the computer? Options are hard_drive, power_supply, cpu, gpu, ram, and motherboard, with space delimiters." crlf)
	(assert (current_parts (readline)))
)

(deffacts init
	(current_price 0)
)

