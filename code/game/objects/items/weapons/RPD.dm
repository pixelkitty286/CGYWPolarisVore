#define PAINT_MODE -2
#define EATING_MODE -1
#define ATMOS_MODE 0
#define DISPOSALS_MODE 1
#define TRANSIT_MODE 2

/obj/item/weapon/pipe_dispenser
	name = "Rapid Piping Device (RPD)"
	desc = "A device used to rapidly pipe things."
	icon = 'icons/obj/tools.dmi'
	icon_state = "rpd"
	flags = NOBLUDGEON
	force = 10
	throwforce = 10
	throw_speed = 1
	throw_range = 5
	w_class = ITEMSIZE_NORMAL
	matter = list(DEFAULT_WALL_MATERIAL = 50000, "glass" = 25000)
	var/datum/effect/effect/system/spark_spread/spark_system
	var/working = 0
	var/mode = ATMOS_MODE
	var/p_dir = NORTH
	var/p_flipped = FALSE
	var/paint_color="grey"
	var/screen = ATMOS_MODE //Starts on the atmos tab.
	var/piping_layer = PIPING_LAYER_DEFAULT
	var/wrench_mode = FALSE
	var/obj/item/weapon/tool/wrench/tool
	var/datum/pipe_recipe/recipe
	var/static/datum/pipe_recipe/first_atmos
	var/static/datum/pipe_recipe/first_disposal

/obj/item/weapon/pipe_dispenser/New()
	. = ..()
	src.spark_system = new /datum/effect/effect/system/spark_spread
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)
	tool = new /obj/item/weapon/tool/wrench/cyborg(src) // RPDs have wrenches inside of them, so that they can wrench down spawned pipes without being used as superior wrenches themselves.

/obj/item/weapon/pipe_dispenser/proc/SetupPipes()
	if(!first_atmos)
		first_atmos = atmos_pipe_recipes[atmos_pipe_recipes[1]][1]
		recipe = first_atmos
	if(!first_disposal)
		first_disposal = disposal_pipe_recipes[disposal_pipe_recipes[1]][1]

/obj/item/weapon/pipe_dispenser/Destroy()
	qdel(spark_system)
	spark_system = null
	return ..()

/obj/item/weapon/pipe_dispenser/suicide_act(mob/user)
	var/datum/gender/TU = gender_datums[user.get_visible_gender()]
	user.visible_message("<span class='suicide'>[user] points the end of the RPD down [TU.his] throat and presses a button! It looks like [TU.hes] trying to commit suicide...</span>")
	playsound(get_turf(user), 'sound/machines/click.ogg', 50, 1)
	playsound(get_turf(user), 'sound/items/deconstruct.ogg', 50, 1)
	return(BRUTELOSS)

/obj/item/weapon/pipe_dispenser/attack_self(mob/user)
	src.interact(user)

/obj/item/weapon/pipe_dispenser/interact(mob/user)
	SetupPipes()
	var/list/lines = list()
	if(mode >= ATMOS_MODE)
		lines += "<div class=\"block\"><h3>Direction:</h3><div class=\"item\">"
		var/icon/preview = null
		var/icon/previewm = null
		if(recipe.icon && recipe.icon_state)
			preview = new /icon(recipe.icon, recipe.icon_state)
			if (recipe.icon_state_m)
				previewm = new /icon(recipe.icon, recipe.icon_state_m)
		switch(recipe.dirtype)

			if(PIPE_STRAIGHT) // Straight, N-S, W-E
				lines += render_dir_img(preview,user,NORTH,"Vertical","&#8597;")
				lines += render_dir_img(preview,user,EAST,"Horizontal","&harr;")

			if(PIPE_BENDABLE) // Bent, N-W, N-E etc
				lines += render_dir_img(preview,user,NORTH,"Vertical","&#8597;")
				lines += render_dir_img(preview,user,EAST,"Horizontal","&harr;")
				lines += "<br />"
				lines += render_dir_img(preview,user,NORTHWEST,"West to North","&#9565;")
				lines += render_dir_img(preview,user,NORTHEAST,"North to East","&#9562;")
				lines += "<br />"
				lines += render_dir_img(preview,user,SOUTHWEST,"South to West","&#9559;")
				lines += render_dir_img(preview,user,SOUTHEAST,"East to South","&#9556;")

			if(PIPE_TRINARY) // Manifold
				lines += render_dir_img(preview,user,NORTH,"West South East","&#9574;")
				lines += render_dir_img(preview,user,EAST,"North West South","&#9571;")
				lines += "<br />"
				lines += render_dir_img(preview,user,SOUTH,"East North West","&#9577;")
				lines += render_dir_img(preview,user,WEST,"South East North","&#9568;")

			if(PIPE_TRIN_M) // Mirrored ones
			//each mirror icon is 45 anticlockwise from it's real direction
				lines += render_dir_img(preview,user,NORTH,"West South East","&#9574;")
				lines += render_dir_img(preview,user,EAST,"North West South","&#9571;")
				lines += "<br />"
				lines += render_dir_img(preview,user,SOUTH,"East North West","&#9577;")
				lines += render_dir_img(preview,user,WEST,"South East North","&#9568;")
				lines += "<br />"
				lines += render_dir_img(previewm,user,SOUTH,"West South East","&#9574;", 1)
				lines += render_dir_img(previewm,user,EAST,"North West South","&#9571;", 1)
				lines += "<br />"
				lines += render_dir_img(previewm,user,NORTH,"East North West","&#9577;", 1)
				lines += render_dir_img(previewm,user,WEST,"South East North","&#9568;", 1)

			if(PIPE_DIRECTIONAL) // Stuff with four directions - includes pumps etc.
				lines += render_dir_img(preview,user,NORTH,"North","&uarr;")
				lines += render_dir_img(preview,user,EAST,"East","&rarr;")
				lines += render_dir_img(preview,user,SOUTH,"South","&darr;")
				lines += render_dir_img(preview,user,WEST,"West","&larr;")

			if(PIPE_ONEDIR) // Single icon_state (eg 4-way manifolds)
				lines += render_dir_img(preview,user,SOUTH,"Pipe","&#8597;")
		lines += "</div></div>"

	if(mode == ATMOS_MODE || mode == PAINT_MODE)
		lines += "<div class=\"block\"><h3>Color:</h3>"
		var/i = 0
		for(var/c in pipe_colors)
			++i
			lines += "<a class='[paint_color == c? "linkOn" : ""]' href='?src=\ref[src];paint_color=[c]'>[c]</a>"
			if(i == 4)
				lines += "<br>"
				i = 0
		lines += "</div>"

	lines += "<div class=\"block\"><h3>Utilities:</h3>"
	lines += "<a class='[mode >= ATMOS_MODE ? "linkOn" : ""]' href='?src=\ref[src];mode=[screen]'>Lay Pipes</a>"
	lines += "<a class='[mode == EATING_MODE ? "linkOn" : ""]' href='?src=\ref[src];mode=[EATING_MODE]'>Eat Pipes</a>"
	lines += "<a class='[mode == PAINT_MODE ? "linkOn" : ""]' href='?src=\ref[src];mode=[PAINT_MODE]'>Paint Pipes</a>"
	lines += "</div>"

	lines += "<div class=\"block\"><h3>Catagory:</h3>"
	lines += "<a class='[screen == ATMOS_MODE ? "linkOn" : ""]' href='?src=\ref[src];screen=[ATMOS_MODE]'>Atmospherics</a>"
	lines += "<a class='[screen == DISPOSALS_MODE ? "linkOn" : ""]' href='?src=\ref[src];screen=[DISPOSALS_MODE]'>Disposals</a>"
	//lines += "<a class='[screen == TRANSIT_MODE ? "linkOn" : ""]' href='?src=\ref[src];screen=[TRANSIT_MODE]'>Transit Tube</a>"
	lines += "<br><a class='[wrench_mode ? "linkOn" : ""]' href='?src=\ref[src];switch_wrench=1;wrench_mode=[!wrench_mode]'>Wrench Mode</a>"
	lines += "</div>"

	if(screen == ATMOS_MODE)
		for(var/category in atmos_pipe_recipes)
			lines += "<div class=\"block\"><h3>[category]:</h3>"
			if(category == "Pipes")
				lines += "<div class=\"item\">"
				lines += "<a class='[piping_layer == PIPING_LAYER_REGULAR ? "linkOn" : "linkOff"]' href='?src=\ref[src];piping_layer=[PIPING_LAYER_REGULAR]'>Regular</a> "
				lines += "<a class='[piping_layer == PIPING_LAYER_SUPPLY ? "linkOn" : "linkOff"]' href='?src=\ref[src];piping_layer=[PIPING_LAYER_SUPPLY]'>Supply</a> "
				lines += "<a class='[piping_layer == PIPING_LAYER_SCRUBBER ? "linkOn" : "linkOff"]' href='?src=\ref[src];piping_layer=[PIPING_LAYER_SCRUBBER]'>Scrubber</a> "
				lines += "</div>"
			for(var/i in 1 to atmos_pipe_recipes[category].len)
				var/datum/pipe_recipe/PI = atmos_pipe_recipes[category][i]
				lines += "<div class=\"item\">"
				lines += "<a class='[recipe == PI ? "linkOn" : ""]' href='?src=\ref[src]&category=[category]&pipe_type=[i]'>[PI.name]</a>"
				lines += "</div>"
			lines += "</div>"
	else if(screen == DISPOSALS_MODE)
		for(var/category in disposal_pipe_recipes)
			lines += "<div class=\"block\"><h3>[category]:</h3>"
			for(var/i in 1 to disposal_pipe_recipes[category].len)
				var/datum/pipe_recipe/PI = disposal_pipe_recipes[category][i]
				lines += "<div class=\"item\">"
				lines += "<a class='[recipe == PI ? "linkOn" : ""]' href='?src=\ref[src]&category=[category]&pipe_type=[i]'>[PI.name]</a>"
				lines += "</div>"
			lines += "</div>"

	var/dat = lines.Join()
	var/datum/browser/popup = new(user, "rpd", name, 300, 800, src)
	popup.set_content("<TT>[dat]</TT>")
	popup.open()

/obj/item/weapon/pipe_dispenser/Topic(href,href_list)
	SetupPipes()
	if(..())
		return
	if(!usr.canmove || usr.stat || usr.restrained() || !in_range(loc, usr))
		return
	var/playeffect = TRUE // Do we spark the device
	var/anyclicked = FALSE // Tells us if we need to refresh the window.
	if(href_list["paint_color"])
		paint_color = href_list["paint_color"]
		playeffect = FALSE
		anyclicked = TRUE
	if(href_list["mode"])
		mode = text2num(href_list["mode"])
		anyclicked = TRUE
	if(href_list["screen"])
		if(mode == screen)
			mode = text2num(href_list["screen"])
		screen = text2num(href_list["screen"])
		switch(screen)
			if(DISPOSALS_MODE)
				recipe = first_disposal
			if(ATMOS_MODE)
				recipe = first_atmos
		p_dir = NORTH
		playeffect = FALSE
		anyclicked = TRUE
	if(href_list["piping_layer"])
		piping_layer = text2num(href_list["piping_layer"])
		playeffect = FALSE
		anyclicked = TRUE
	if(href_list["pipe_type"])
		recipe = all_pipe_recipes[href_list["category"]][text2num(href_list["pipe_type"])]
		if(recipe.dirtype == PIPE_ONEDIR)	// One hell of a hack for the fact that the image previews for the onedir types only show on the south, but the default pipe type is north.
			p_dir = SOUTH					// Did I fuck this up? Maybe. Or maybe it's just the icon files not being ready for an RPD.
		else								// If going to try and fix this hack, be aware the pipe dispensers might rely on pipes defaulting south instead of north.
			p_dir = NORTH
		p_flipped = FALSE
		anyclicked = TRUE
	if(href_list["dir"])
		p_dir = text2dir(href_list["dir"])
		p_flipped = text2num(href_list["flipped"])
		playeffect = FALSE
		anyclicked = TRUE
	if(href_list["switch_wrench"])
		wrench_mode = text2num(href_list["wrench_mode"])
		anyclicked = TRUE
	if(anyclicked)
		if(playeffect)
			spark_system.start()
			playsound(get_turf(src), 'sound/effects/pop.ogg', 50, 0)
		src.interact(usr)

/obj/item/weapon/pipe_dispenser/afterattack(atom/A, mob/user as mob, proximity)
	if(!user.IsAdvancedToolUser() || istype(A, /turf/space/transit) || !proximity)
		return ..()

	//So that changing the menu settings doesn't affect the pipes already being built.
	var/queued_piping_layer = piping_layer
	var/queued_p_type = recipe.pipe_type
	var/queued_p_dir = p_dir
	var/queued_p_flipped = p_flipped
	var/queued_p_subtype = recipe.subtype
	var/queued_p_paintable = recipe.paintable

	//make sure what we're clicking is valid for the current mode
	var/static/list/make_pipe_whitelist // This should probably be changed to be in line with polaris standards. Oh well.
	if(!make_pipe_whitelist)
		make_pipe_whitelist = typecacheof(list(/obj/structure/lattice, /obj/structure/girder, /obj/item/pipe))
	var/can_make_pipe = (isturf(A) || is_type_in_typecache(A, make_pipe_whitelist))

	. = FALSE
	switch(mode) //if we've gotten this var, the target is valid
		if(PAINT_MODE) //Paint pipes
			if(!istype(A, /obj/machinery/atmospherics/pipe))
				return ..()
			var/obj/machinery/atmospherics/pipe/P = A
			playsound(get_turf(src), 'sound/machines/click.ogg', 50, 1)
			P.change_color(pipe_colors[paint_color])
			user.visible_message("<span class='notice'>[user] paints \the [P] [paint_color].</span>","<span class='notice'>You paint \the [P] [paint_color].</span>")
			return

		if(EATING_MODE) //Eating pipes
			if(!(istype(A, /obj/item/pipe) || istype(A, /obj/item/pipe_meter) || istype(A, /obj/structure/disposalconstruct)))
				return ..()
			to_chat(user, "<span class='notice'>You start destroying a pipe...</span>")
			playsound(get_turf(src), 'sound/machines/click.ogg', 50, 1)
			if(do_after(user, 2, target = A))
				activate()
				qdel(A)

		if(ATMOS_MODE) //Making pipes
			if(!can_make_pipe)
				return ..()
			playsound(get_turf(src), 'sound/machines/click.ogg', 50, 1)
			if (istype(recipe, /datum/pipe_recipe/meter))
				to_chat(user, "<span class='notice'>You start building a meter...</span>")
				if(do_after(user, 2, target = A))
					activate()
					var/obj/item/pipe_meter/PM = new /obj/item/pipe_meter(get_turf(A))
					PM.setAttachLayer(queued_piping_layer)
					if(wrench_mode)
						do_wrench(PM, user)
			else
				to_chat(user, "<span class='notice'>You start building a pipe...</span>")
				if(do_after(user, 2, target = A))
					activate()
					var/obj/machinery/atmospherics/path = queued_p_type
					var/pipe_item_type = initial(path.construction_type) || /obj/item/pipe
					var/obj/item/pipe/P = new pipe_item_type(get_turf(A), queued_p_type, queued_p_dir)

					P.update()
					P.add_fingerprint(usr)
					P.setPipingLayer(queued_piping_layer)
					if (queued_p_paintable)
						P.color = pipe_colors[paint_color]
					if(queued_p_flipped)
						P.do_a_flip()
					if(wrench_mode)
						do_wrench(P, user)

		if(DISPOSALS_MODE) //Making disposals pipes
			if(!can_make_pipe)
				return ..()
			A = get_turf(A)
			if(istype(A, /turf/unsimulated))
				to_chat(user, "<span class='warning'>[src]'s error light flickers; there's something in the way!</span>")
				return
			to_chat(user, "<span class='notice'>You start building a disposals pipe...</span>")
			playsound(get_turf(src), 'sound/machines/click.ogg', 50, 1)
			if(do_after(user, 4, target = A))
				var/obj/structure/disposalconstruct/C = new(A, queued_p_type, queued_p_dir, queued_p_flipped, queued_p_subtype)

				if(!C.can_place())
					to_chat(user, "<span class='warning'>There's not enough room to build that here!</span>")
					qdel(C)
					return

				activate()

				C.add_fingerprint(usr)
				C.update_icon()
				if(wrench_mode)
					do_wrench(C, user)
				return

		else
			return ..()


/obj/item/weapon/pipe_dispenser/proc/activate()
	playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)

/obj/item/weapon/pipe_dispenser/proc/do_wrench(var/atom/target, mob/user)
	var/resolved = target.attackby(tool,user)
	if(!resolved && tool && target)
		tool.afterattack(target,user,1)

/obj/item/weapon/pipe_dispenser/proc/render_dir_img(preview,user,_dir,title,noimg,flipped=0)
	var/dirtext = dir2text(_dir)
	var/selected = " style=\"height:34px;width:34px;display:inline-block\""
	if(_dir == p_dir && flipped == p_flipped)
		selected += " class=\"linkOn\""
	if(preview)
		user << browse_rsc(new /icon(preview, dir=_dir), "[dirtext][flipped ? "m" : ""].png")
		return "<a href=\"?src=\ref[src];dir=[dirtext];flipped=[flipped]\" title=\"[title]\"[selected]\"><img src=\"[dirtext][flipped ? "m" : ""].png\" /></a>"
	else
		return "<a href=\"?src=\ref[src];dir=[dirtext];flipped=[flipped]\" title=\"[title]\"[selected]\">[noimg]</a>"


#undef PAINT_MODE
#undef EATING_MODE
#undef ATMOS_MODE
#undef DISPOSALS_MODE
