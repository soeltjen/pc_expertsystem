
(defrule parse_data_file
)

; Ask the user if they have a budget
(defrule price_pref
	initial-fact
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
	initial-fact
	=>
	(printout t "What parts do you not already have and need to use in the computer? Options are hard_drive, power_supply, and gpu, with space delimiters." crlf)
	(assert (current_parts (readline)))
)

; Add ram to a build that doesn't have one

; Add cpu to a build that doesn't have one

; Main build rule
(defrule build
	(bind ?price_local 0)
	(price_max ?higher)
	(ram_mem_min ?ram_mem_min)

	?ram <- (ram (size ?size&:(>= ?size ?ram_mem_min))
				 (frequency ?frequency)
				 (price ?p&:(< (+ ?p ?price_local) ?higher))
	)
	
	(cpu_cores_min ?cpu_cores_min)
	?cpu <- (cpu (cores ?cores&:(>= ?cores ?cpu_cores_min))
				 (chipset ?chipset)
	)
	
	?mobo <- (motherboard (chipset ?chipset)
						  (ram_freqs ?$ ?frequency ?$)
						  
	)
	=>
)

; If budget is below a certain price, then remove gpu and replace CPU with integrated graphics
; For just cpu, ram, and mobo, the threshold is $250
; power supply and hard drive are each $50 extra

; Fill out a basic computer using parts the user has already selected

; If there aren't any possible builds
(defrule no_results
	(salience -100)
	(test (not (exists (build (status complete)))))
	=>
	(printout "Given your preferences, there is no PC that we can build using the parts in our database at this time." crlf)
	(exit)
)

(deffacts init
	(need cpu)
	(need ram)
	(need motherboard)
	(build (status incomplete))
)

