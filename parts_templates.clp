
(deftemplate cpu
	(slot id)
	(slot socket)
	(slot cores (type INTEGER))
	(slot threads (type INTEGER))
	(slot clock_rate (type NUMBER))
	(slot overclockable (allowed-symbols true false))
	(slot wattage (type INTEGER))
	(slot price (type NUMBER))
	(slot cooler (allowed-symbols true false))
)

(deftemplate ram
	(slot id)
	(slot sticks)
	(slot stick_size (type INTEGER))
	(slot standard (allowed-symbols ddr4))
	(slot frequency (type NUMBER))
	(slot channelling
		(allowed-symbols single dual quad))
	(slot price)
)

(deftemplate gpu
	(slot id)
	(slot mem_size)
	(slot mem_type)
	(slot wattage)
	(slot price)
)

(deftemplate hard_drive
	(slot id)
	(slot size)
	(slot speed)
	(slot connection (allowed-symbols pci sata usb))
	(slot price)
)

(deftemplate motherboard
	(slot id)
	(slot ram_slots (type INTEGER))
	(slot ram_max (type INTEGER))
	(slot ram_standard (allowed-symbols ddr4))
	(multislot ram_freqs (type INTEGER))
	(slot socket)
	(slot form_factor (allowed-symbols atx mini-atx micro-atx))
	(slot pci_slots (type INTEGER))
	(slot price (type NUMBER))
	(slot channelling
		(allowed-symbols single dual quad))
)

(deftemplate powersupply
	(slot wattage)
	(slot price)
)

(deftemplate computer
	(slot cpu)
	(slot gpu)
	(slot ram)
	(slot hard_drive)
	(slot motherboard)
	(slot powersupply)
)

