/obj/structure/noticeboard
	name = "notice board"
	desc = "A board for pinning important notices upon."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "nboard00"
	density = 0
	anchored = 1
	var/notices = 0

/obj/structure/noticeboard/New(var/loc, var/dir, var/building = 0)
	..()

	if(building)
		if(loc)
			src.loc = loc

		pixel_x = (dir & 3)? 0 : (dir == 4 ? -32 : 32)
		pixel_y = (dir & 3)? (dir ==1 ? -27 : 27) : 0
		update_icon()
		return

/obj/structure/noticeboard/Initialize()
	for(var/obj/item/I in loc)
		if(notices > 4) break
		if(istype(I, /obj/item/weapon/paper))
			I.loc = src
			notices++
	icon_state = "nboard0[notices]"
	. = ..()

//attaching papers!!
/obj/structure/noticeboard/attackby(var/obj/item/weapon/O as obj, var/mob/user as mob)
	if(istype(O, /obj/item/weapon/paper))
		if(notices < 5)
			O.add_fingerprint(user)
			add_fingerprint(user)
			user.drop_from_inventory(O)
			O.loc = src
			notices++
			icon_state = "nboard0[notices]"	//update sprite
			to_chat(user, "<span class='notice'>You pin the paper to the noticeboard.</span>")
		else
			to_chat(user, "<span class='notice'>You reach to pin your paper to the board but hesitate. You are certain your paper will not be seen among the many others already attached.</span>")
	if(O.is_wrench())
		to_chat(user, "<span class='notice'>You start to unwrench the noticeboard.</span>")
		playsound(src.loc, O.usesound, 50, 1)
		if(do_after(user, 15 * O.toolspeed))
			to_chat(user, "<span class='notice'>You unwrench the noticeboard.</span>")
			new /obj/item/frame/noticeboard( src.loc )
			qdel(src)
		return

/obj/structure/noticeboard/attack_hand(var/mob/user)
	examine(user)

// Since Topic() never seems to interact with usr on more than a superficial
// level, it should be fine to let anyone mess with the board other than ghosts.
/obj/structure/noticeboard/examine(var/mob/user)
	if(!user)
		user = usr
	if(user.Adjacent(src))
		var/dat = "<B>Noticeboard</B><BR>"
		for(var/obj/item/weapon/paper/P in src)
			dat += "<A href='?src=\ref[src];read=\ref[P]'>[P.name]</A> <A href='?src=\ref[src];write=\ref[P]'>Write</A> <A href='?src=\ref[src];remove=\ref[P]'>Remove</A><BR>"
		user << browse("<HEAD><TITLE>Notices</TITLE></HEAD>[dat]","window=noticeboard")
		onclose(user, "noticeboard")
	else
		..()

/obj/structure/noticeboard/Topic(href, href_list)
	..()
	usr.set_machine(src)
	if(href_list["remove"])
		if((usr.stat || usr.restrained()))	//For when a player is handcuffed while they have the notice window open
			return
		var/obj/item/P = locate(href_list["remove"])
		if(P && P.loc == src)
			P.loc = get_turf(src)	//dump paper on the floor because you're a clumsy fuck
			P.add_fingerprint(usr)
			add_fingerprint(usr)
			notices--
			icon_state = "nboard0[notices]"
	if(href_list["write"])
		if((usr.stat || usr.restrained())) //For when a player is handcuffed while they have the notice window open
			return
		var/obj/item/P = locate(href_list["write"])
		if((P && P.loc == src)) //ifthe paper's on the board
			var/mob/living/M = usr
			if(istype(M))
				var/obj/item/weapon/pen/E = M.get_type_in_hands(/obj/item/weapon/pen)
				if(E)
					add_fingerprint(M)
					P.attackby(E, usr)
				else
					to_chat(M, "<span class='notice'>You'll need something to write with!</span>")
	if(href_list["read"])
		var/obj/item/weapon/paper/P = locate(href_list["read"])
		if((P && P.loc == src))
			usr << browse("<HTML><HEAD><TITLE>[P.name]</TITLE></HEAD><BODY><TT>[P.info]</TT></BODY></HTML>", "window=[P.name]")
			onclose(usr, "[P.name]")
	return
