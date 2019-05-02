
;----------------------
;   READING DATABASE
;----------------------

(defrule open_datafile
	(initial-fact)
	=>
	(open "testdata" testdata "r")
	(assert (phase reading))
)

(defrule read_datafile
	?phase <- (phase reading)
	=>
	(bind ?line (readline testdata))
	(retract ?phase)
	(if (neq ?line EOF)
		then
			(bind ?part (explode$ ?line))
			(assert (part ?part))
			(assert (phase reading))
		else
			(retract ?phase)
			(close testdata)
			(assert (phase parsing))
	)
)

(defrule cpu_templ_conv
	?cpu <- (part cpu ?id ?sock ?cores ?clock ?wattage ?price)
	=>
	(retract ?cpu)
	(assert (cpu (id ?id) (socket ?sock) (clock_rate ?clock) (wattage ?wattage) (price ?price)))
)

(defrule mobo_templ_conv
	?mobo <- (part motherboard ?id ?sock ?freqs ?price)
	=>
	(retract ?mobo)
	(bind ?freqs_mf (explode$ ?freqs))
	(assert (motherboard (id ?id) (socket ?sock) (ram_freqs ?freqs_mf) (price ?price)))
)

(defrule ram_templ_conv
	?ram <- (part ram ?id ?sticks ?stick_size ?freq ?price)
	=>
	(retract ?ram)
	(assert (ram (id ?id) (sticks ?sticks) (stick_size ?stick_size) (frequency ?freq) (price ?price)))
)

(defrule hd_templ_conv
	?hd <- (part hard_drive ?id ?size ?speed ?price)
	=>
	(retract ?hd)
	(assert (hard_drive (id ?id) (size ?size) (speed ?speed) (price ?price)))
)

;---------------------
;    QUERYING USER
;---------------------

; Ask the user if they have a budget
(defrule price_pref
	(phase querying)
	=>
	(printout t "Do you have lower and/or upper limit on your budget?  If so, respond with yes and a lower limit and upper limit, or just respond with no: ")
	(assert (price_pref (read)))
)

(defrule parse_price_pref
	?p <- (price_pref ?ans $?min $?max)
	(and (exist $?min) (exist $?max))
	=>
	(retract ?p)
	(assert (price_min ?lower))
	(assert (price_max ?higher))
)

; Ask the user if they have any cpu preferences
(defrule cpu_pref
	(phase querying)
	?req <- (need cpu)
	=>
	(retract ?req)
	(printout t "What is the minimum amount of cores the CPU should have (type '0' if you don't care): ")
	(assert (cpu_cores_min (read)))
)

; Ask the user if they have any gpu preferences
(defrule gpu_pref
	(phase querying)
	?req <- (need gpu)
	=>
	(retract ?req)
	(printout t "What is the minimum amount of memory (in gigabytes) the GPU should have (type '0' if you don't care): ")
	(assert (gpu_mem_min (read)))
)

; Ask the user if they have any ram preferences
(defrule ram_pref
	(phase querying)
	?req <- (need ram)
	=>
	(retract ?req)
	(printout t "What is the minimum amount of memory (in gigabytes) that the RAM should have (8 is the recommended minimum): ")
	(assert (ram_mem_min (read)))
)

; Ask the user if they have any hard drive preferences
(defrule hd_pref
	(phase querying)
	?req <- (need hd)
	=>
	(retract ?req)
	(printout t "What is the minimum amount of space (in gigabytes) that the hard drive should have (1 terabyte is 1024 gigabytes): ")
	(assert (hd_mem_min (read)))
)

; Ask the user what parts they already have and plan to use in the new build.  For example, they may already have a hard drive, power supply, or gpu
; Future parts to add: cpu, ram, motherboard, solid state drive
(defrule current_parts
	(phase querying)
	=>
	(printout t "What parts do you not already have and need to use in the computer? Options are hard_drive, power_supply, and gpu, with space delimiters." crlf)
	(assert (current_parts (readline)))
)

;---------------------
;    ADDING PARTS
;---------------------

; Add ram to a build that doesn't have one
(defrule add_ram
	(phase building)
	(build parts $?parts part_ids $?part_ids wattage ?w price ?p status incomplete)
	(not (member$ ram $?parts))

	; RAM needs to check compatiblity with motherboard if one is already in the build
	(ram (id ?id) (sticks ?sticks) (stick_size ?stick_size) (frequency ?freq) (price ?p1))

	(price_min ?lower)
	(price_max ?higher)
	(test (> (+ ?p ?p1) ?lower))
	(test (< (+ ?p ?p1) ?higher))
	=>
	(assert
		(build	parts ram $?parts
			part_ids ?id $?part_ids
			wattage ?w
			price (+ ?p ?p1)
			status incomplete
		)
	)
)

; Add cpu to a build that doesn't have one
(defrule add_cpu
	(phase building)
	(build parts $?parts part_ids $?part_ids wattage ?w price ?p status incomplete)
	(not (member$ cpu $?parts))

	; CPU needs to check compatiblity with motherboard if one is already in the build
	(cpu (id ?id) (socket ?sock) (clock_rate ?clock) (wattage ?wattage) (price ?p1))

	(price_min ?lower)
	(price_max ?higher)
	(test (> (+ ?p ?p1) ?lower))
	(test (< (+ ?p ?p1) ?higher))
	=>
	(assert
		(build	parts cpu $?parts
			part_ids ?id $?part_ids
			wattage ?w
			price (+ ?p ?p1)
			status incomplete
		)
	)
)

; Add a motherboard to a build that doesn't have one
(defrule add_motherboard
	(phase building)
	(build parts $?parts part_ids $?part_ids wattage ?w price ?p status incomplete)
	(not (member$ motherboard $?parts))

	; motherboard needs to check compatiblity with CPU and RAM if they are already in the build
	(motherboard (id ?id) (socket ?sock) (ram_freqs ?freqs_mb) (price ?p1))

	(price_min ?lower)
	(price_max ?higher)
	(test (> (+ ?p ?p1) ?lower))
	(test (< (+ ?p ?p1) ?higher))
	=>
	(assert
		(build 	parts motherboard $?parts
			part_ids ?id $?part_ids
			wattage ?w
			price (+ ?p ?p1)
			status incomplete
		)
	)
)

; Mark a build as complete if it has all the necessary parts to boot
; Don't retract the incomplete build, in case it causes the rule to fire again
(defrule mark_complete
	(build parts $?parts part_ids $?rest status incomplete)
	(member$ motherboard $?parts)
	(member$ cpu $?parts)
	(member$ ram $?parts)
	(member$ motherboard $?parts)
	=>
	(assert
		(build 	parts motherboard $?parts
			part_ids $?rest
			status complete
		)
	)
)

; If budget is below a certain price, then remove gpu and replace CPU with integrated graphics
; For just cpu, ram, and mobo, the threshold is $250
; power supply and hard drive are each $50 extra

; If there aren't any possible builds
(defrule no_results
	(salience -100)
	(not (exists (build $? status complete)))
	=>
	(printout t "Given your preferences, there is no PC that we can build using the parts in our database at this time." crlf)
	(exit)
)

(deffacts init
	(need cpu)
	(need ram)
	(need motherboard)
	(build	parts
		part_ids
		wattage 0
		price 0
		status incomplete)
)

