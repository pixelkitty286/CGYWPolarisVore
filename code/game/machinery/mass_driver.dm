//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

/obj/machinery/mass_driver
	name = "mass driver"
	desc = "Shoots things into space."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "mass_driver"
	anchored = 1.0
	use_power = USE_POWER_IDLE
	idle_power_usage = 2
	active_power_usage = 50
	circuit = /obj/item/weapon/circuitboard/mass_driver

	var/power = 1.0
	var/code = 1.0
	var/id = 1.0
	var/drive_range = 50 //this is mostly irrelevant since current mass drivers throw into space, but you could make a lower-range mass driver for interstation transport or something I guess.

/obj/machinery/mass_driver/New()
	..()
	component_parts = list()
	component_parts += new /obj/item/weapon/stock_parts/motor(src)
	component_parts += new /obj/item/weapon/stock_parts/motor(src)
	component_parts += new /obj/item/weapon/stock_parts/gear(src)
	component_parts += new /obj/item/weapon/stock_parts/gear(src)
	component_parts += new /obj/item/weapon/stock_parts/spring(src)
	component_parts += new /obj/item/weapon/stock_parts/capacitor(src)
	component_parts += new /obj/item/stack/cable_coil(src, 5)
	RefreshParts()

/obj/machinery/mass_driver/attackby(var/obj/item/I, mob/user)
	if(default_deconstruction_screwdriver(user, I))
		return
	if(default_deconstruction_crowbar(user, I))
		return

	if(istype(I, /obj/item/device/multitool))
		if(panel_open)
			var/input = sanitize(input(usr, "What id would you like to give this conveyor?", "Multitool-Conveyor interface", id))
			if(!input)
				to_chat(usr, "No input found please hang up and try your call again.")
				return
			id = input
			return
	return

/obj/machinery/mass_driver/proc/drive(amount)
	if(stat & (BROKEN|NOPOWER))
		return
	use_power(500)
	var/O_limit
	var/atom/target = get_edge_target_turf(src, dir)
	for(var/atom/movable/O in loc)
		if(!O.anchored||istype(O, /obj/mecha))//Mechs need their launch platforms.
			O_limit++
			if(O_limit >= 20)
				for(var/mob/M in hearers(src, null))
					to_chat(M, "<span class='notice'>The mass driver lets out a screech, it mustn't be able to handle any more items.</span>")
				break
			use_power(500)
			spawn(0)
				O.throw_at(target, drive_range * power, power)
	flick("mass_driver1", src)
	return

/obj/machinery/mass_driver/emp_act(severity)
	if(stat & (BROKEN|NOPOWER))
		return
	drive()
	..(severity)
