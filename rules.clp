
;----------------------
;   READING DATABASE
;----------------------

(defrule open_datafile
	(salience 100)
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

(defrule explode_freqs
	?mobo <- (part motherboard ?id ?sock ?freqs ?price)
	=>
	(retract ?mobo)
	(bind ?freqs_mf (explode$ ?freqs))
	(assert (part motherboard ?id ?sock (create$ ?freqs_mf) ?price))
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
	?req <- (need gpu)
	=>
	(retract ?req)
	(printout t "What is the minimum amount of memory (in gigabytes) the GPU should have (type '0' if you don't care): ")
	(assert (gpu_mem_min (read)))
)

; Ask the user if they have any ram preferences
(defrule ram_pref
	?req <- (need ram)
	=>
	(retract ?req)
	(printout t "What is the minimum amount of memory (in gigabytes) that the RAM should have (8 is the recommended minimum): ")
	(assert (ram_mem_min (read)))
)

; Ask the user if they have any hard drive preferences
(defrule hd_pref
	?req <- (need hd)
	=>
	(retract ?req)
	(printout t "What is the minimum amount of space (in gigabytes) that the hard drive should have (1 terabyte is 1024 gigabytes): ")
	(assert (hd_mem_min (read)))
)

; Ask the user what parts they already have and plan to use in the new build.  For example, they may already have a hard drive, power supply, or gpu
; Future parts to add: cpu, ram, motherboard, solid state drive
(defrule current_parts
	(initial-fact)
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
	(build (parts $?parts) (part_numbers $?part_nos) (wattage ?w) (price ?p) (status incomplete))
	(not (member$ ram (create$ $?parts)
		 )
	)
	
	; RAM needs to check compatiblity with motherboard if one is already in the build
	(ram ?part_no ?sticks ?size_per_stick ?freq ?price)
	
	(price_min ?lower)
	(price_max ?higher)
	(test (> (+ ?p ?p1) ?lower))
	(test (< (+ ?p ?p1) ?higher))
	=>
	(assert 
		(build 	(part_numbers ?part_no $?part_nos)
				(parts ram $?parts) (wattage ?w)
				(price (+ ?p ?p1)) (status incomplete)
		)		
	)
)

; Add cpu to a build that doesn't have one
(defrule add_cpu
	(phase building)
	(build (parts $?parts) (part_numbers $?part_nos) (wattage ?w) (price ?p) (status incomplete))
	(not (member$ cpu (create$ $?parts)
		 )
	)
	
	; CPU needs to check compatiblity with motherboard if one is already in the build
	(cpu ?part_no ?sticks ?size_per_stick ?freq ?price)
	
	(price_min ?lower)
	(price_max ?higher)
	(test (> (+ ?p ?p1) ?lower))
	(test (< (+ ?p ?p1) ?higher))
	=>
	(assert 
		(build 	(part_numbers ?part_no $?part_nos)
				(parts cpu $?parts) (wattage ?w)
				(price (+ ?p ?p1)) (status incomplete)
		)		
	)
)

; Add a motherboard to a build that doesn't have one
(defrule add_motherboard
	(phase building)
	(build (parts $?parts) (part_numbers $?part_nos) (wattage ?w) (price ?p) (status incomplete))
	(not (member$ motherboard (create$ $?parts))
	)
	
	; motherboard needs to check compatiblity with CPU and RAM if they are already in the build
	(motherboard ?part_no ?socket ?freqs ?price)
	
	(price_min ?lower)
	(price_max ?higher)
	(test (> (+ ?p ?p1) ?lower))
	(test (< (+ ?p ?p1) ?higher))
	=>
	(assert 
		(build 	(part_numbers ?part_no $?part_nos)
				(parts motherboard $?parts) (wattage ?w)
				(price (+ ?p ?p1)) (status incomplete)
		)		
	)
)

; Mark a build as complete if it has all the necessary parts to boot
; Don't retract the incomplete build, in case it causes the rule to fire again
(defrule mark_complete
	(build (status incomplete) (cpu ?cpu_p) (ram ?ram_p)
				 (hard_drive ?hd_p) (motherboard ?m_p) (power_supply ?ps_p))
	=>
	(assert (build (status complete) (cpu ?cpu_p) (ram ?ram_p)
				 (hard_drive ?hd_p) (motherboard ?m_p) (power_supply ?ps_p)))
)

; Main build rule
;(defrule build
;	(bind ?price_local 0)
;	(price_max ?higher)
;	(ram_mem_min ?ram_mem_min)
;	?ram <- (ram (size ?size&:(>= ?size ?ram_mem_min))
;				 (frequency ?frequency)
;				 (price ?p&:(< (+ ?p ?price_local) ?higher))
;	)
;	(cpu_cores_min ?cpu_cores_min)
;	?cpu <- (cpu (cores ?cores&:(>= ?cores ?cpu_cores_min))
;				 (chipset ?chipset)
;	)
;	?mobo <- (motherboard (chipset ?chipset)
;						  (ram_freqs ?$ ?frequency ?$)
;						  
;	)
;	=>
;)

; If budget is below a certain price, then remove gpu and replace CPU with integrated graphics
; For just cpu, ram, and mobo, the threshold is $250
; power supply and hard drive are each $50 extra

; If there aren't any possible builds
(defrule no_results
	(salience -100)
	(not (exists (build (status complete))))
	=>
	(printout t "Given your preferences, there is no PC that we can build using the parts in our database at this time." crlf)
	(exit)
)

(deffacts init
	(need cpu)
	(need ram)
	(need motherboard)
	(build (status incomplete) (price 0) (wattage 0) (parts))
)

