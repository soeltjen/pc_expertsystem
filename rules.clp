
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
	(need cpu)
	=>
	(printout t "What is the minimum amount of cores the CPU should have (type '0' if you don't care): ")
	(assert (cpu_cores_min (read)))
)

; Ask the user if they have any gpu preferences
(defrule gpu_pref
	(need gpu)
	=>
	(printout t "What is the minimum amount of memory (in gigabytes) the GPU should have (type '0' if you don't care): ")
	(assert (gpu_mem_min (read)))
)

; Ask the user if they have any ram preferences
(defrule ram_pref
	(need ram)
	=>
	(printout t "What is the minimum amount of memory (in gigabytes) that the RAM should have (8 is the recommended minimum): ")
	(assert (ram_mem_min (read)))
)

; Ask the user if they have any hard drive preferences
(defrule hd_pref
	(need hd)
	=>
	(printout t "What is the minimum amount of space (in gigabytes) that the hard drive should have (1 terabyte is 1024 gigabytes): ")
	(assert (hd_mem_min (read)))
)

; Ask the user what parts they already have and plan to use in the new build.  For example, they may already have a hard drive, power supply, or gpu
(defrule current_parts
	initial-fact
	=>
	(printout t "What parts do you not already have and need to use in the computer? Options are hard_drive, power_supply, and gpu, with space delimiters." crlf)
	(assert (current_parts (readline)))
)

; Main build rule
(defrule build
	(ram_mem_min ?ram_mem_min)
	(ram (size ?size&:(>= ?size ?ram_mem_min))
		 (frequency ?frequency)
	)
	
	(cpu_cores_min ?cpu_cores_min)
	(cpu (cores ?cores&:(>= ?cores ?cpu_cores_min))
		 (chipset ?chipset)
	)
	
	(motherboard (chipset ?chipset)
				 (ram_freqs ?frequency)				; BUG:  ram_freqs is a linked list, and we need to make sure ?frequency is in it
	)
	=>
)

; If budget is below a certain price, then remove gpu and replace CPU with integrated graphics
; For just cpu, ram, and mobo, the threshold is $250
; power supply and hard drive are each $50 extra

; If there aren't any possible builds

(deffacts init
	(need cpu)
	(need ram)
	(need motherboard)
	(current_price 0)
)

