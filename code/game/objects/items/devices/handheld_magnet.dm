/obj/item/device/handheld_magnet
	name = "portable mini-magnet"
	desc = "A device used to pull in metallic objects. Requires a power cell to function."
	icon_state = "radio_jammer0"
	flags = FPRINT
	slot_flags = SLOT_BELT
	w_class = W_CLASS_SMALL
	item_state = "electronic"
	materials = list(MAT_IRON = 5000, MAT_GLASS = 1000, MAT_DIAMOND = 1000, MAT_SILVER = 1000)
	w_type = RECYK_ELECTRONIC
	melt_temperature = MELTPOINT_STEEL
	origin_tech = Tc_MAGNETS + "=5;" + Tc_ENGINEERING + "=4;" + Tc_MATERIALS + "=4;" + Tc_PROGRAMMING + "=3;" + Tc_SYNDICATE + "=5;" + Tc_BLUESPACE + "=3"
	autoignition_temperature = AUTOIGNITION_PLASTIC
	var/on = 0
	var/cover_open = 0
	var/base_state = "radio_jammer"
	var/obj/item/weapon/cell/power_src = null
	var/power_usage = 250
	var/pull_interval = 1
	var/magnetic_field = 2
	var/pullcounter = 1

/obj/item/device/handheld_magnet/attack_self(mob/user)
	if (power_src == null || power_src.charge == 0)
		to_chat(user, "<span class='warning'>[src] is unresponsive. Perhaps there's something wrong with its power supply...</span>")
		return
	if (power_src.charge > 0 && power_src.charge < power_usage)
		// suck up the rest of remaining power
		power_src.use(power_usage)
		to_chat(user, "<span class='warning'>[src] flickers a bit, but then dies. Perhaps there's something wrong with its power supply...</span>")
		return

	var/dat = {"Power: <a href='?src=\ref[src];toggleon=1'>[on ? "On" : "Off"]</a><br>
	Range: <a href='?src=\ref[src];magfield=1'>[magnetic_field] metres</a><br>
	Interval: <a href='?src=\ref[src];interval=1'>[pull_interval] deciseconds</a><br>"}

	var/datum/browser/popup = new(user, "\ref[src]", name, 400, 500)
	popup.set_content(dat)
	popup.open()

/obj/item/device/handheld_magnet/Topic(href, href_list)
	if(..())
		return 1
	if(href_list["toggleon"])
		on = !on
		icon_state = "[base_state][on]"

		if (on)
			to_chat(usr, "<span class='notice'>You turn on [src].</span>")
			playsound(src, 'sound/items/radio_jammer.wav', 100, 1)
			magnet_process()
		else
			to_chat(usr, "<span class='warning'>You turn off [src].</span>")
			pullcounter = 1
	else if(href_list["magfield"])
		magnetic_field = input(usr,"Set magnetic field range, from 1 to 7","Field range",magnetic_field) as num
		if(!magnetic_field)
			magnetic_field = 1
		magnetic_field = clamp(magnetic_field,1,7)
	else if(href_list["interval"])
		pull_interval = input(usr,"Set magnetic pull interval","Pull interval",pull_interval) as num
		if(!pull_interval)
			pull_interval = 1
		pull_interval = max(pull_interval,1)
	updateUsrDialog()

/obj/item/device/handheld_magnet/attack_hand(mob/user)
	if (cover_open && power_src && user.is_holding_item(src))
		user.put_in_hands(power_src)
		power_src.add_fingerprint(user)
		power_src.updateicon()

		// Don't rip out cells while the device is working
		// Or at least if its still charged
		if (on)
			if (electrocute_mob(user, power_src, src))
				user.visible_message("<span class='warning'>[user] gets shocked as [src] is still working!</span>", "<span class='warning'>You get shocked as [src] is still working!</span>")
				spark(src)

		src.power_src = null
		user.visible_message("<span class='notice'>[user] removes the cell from [src].</span>", "<span class='notice'>You remove the cell from [src].</span>")
		return
	..()

/obj/item/device/handheld_magnet/attackby(obj/item/W as obj, mob/user as mob)
	if (W.is_screwdriver(user))
		cover_open = !cover_open
		if (cover_open)
			to_chat(user, "<span class='notice'>You open up the power cell cover.</span>")
		else
			to_chat(user, "<span class='notice'>You close the power cell cover.</span>")
		src.add_fingerprint(user)
		return

	if (istype(W, /obj/item/weapon/cell))
		if (cover_open)
			if (power_src)
				to_chat(user, "<span class='warning'>There is already a cell inside, remove it first.</span>")
				return
			if (user.drop_item(W, src))
				power_src = W
				user.visible_message("<span class='notice'>[user] inserts a cell into [src].</span>", "<span class='notice'>You insert a cell into [src].</span>")
				src.add_fingerprint(user)
				return
		else
			to_chat(user, "<span class='warning'>You have to open the cover first, it's closed!</span>")
			return
	..()

/obj/item/device/handheld_magnet/proc/magnet_process()
	while(on)
		if (power_src == null || !power_src.use((power_usage*magnetic_field)/pull_interval))
			on = 0
			icon_state = "[base_state][on]"
			visible_message("<span class='warning'>[src] suddenly shuts down!</span>")
			return

		var/turf/T = get_turf(src)
		if(T)
			for(var/obj/O in orange(magnetic_field, T))
				if(!O.anchored && (O.is_conductor()))
					if(O.w_class && pullcounter % O.w_class != 0) // bigger items take longer
						continue
					if(round((1/O.siemens_coefficient)) > 0 && pullcounter % round((1/O.siemens_coefficient)) != 0) // higher coefficient pulls better
						continue
					if(istype(O,/obj/structure/closet) && get_dist(O,T) < magnetic_field/2)
						var/obj/structure/closet/CL = O
						CL.open()
					step_towards(O, T)

			for(var/mob/living/silicon/S in orange(magnetic_field, T))
				if(istype(S, /mob/living/silicon/ai))
					continue
				if(S.size && pullcounter % S.size != 0) // bigger bots take longer
					continue
				step_towards(S, T)

			for(var/mob/living/carbon/human/H in orange(magnetic_field/2, T))
				if(H.l_store && H.l_store.is_conductor())
					visible_message("<span class='danger'>[src] rips [H.l_store] out of [H]'s left pocket!")
					H.u_equip(H.l_store)
				if(H.r_store && H.r_store.is_conductor())
					visible_message("<span class='danger'>[src] rips [H.r_store] out of [H]'s right pocket!")
					H.u_equip(H.r_store)
		sleep(pull_interval)
		pullcounter++

/obj/item/device/handheld_magnet/examine(mob/user)
	..()
	to_chat(user, "The cover is [cover_open ? "open" : "closed"].")
	to_chat(user, "<span class='warning'>It's turned [on ? "on!" : "off."]</span>")
	// Can only see cell charge % if its turned on
	// or if the cover is open
	if (cover_open)
		to_chat(user, "There is [power_src ? "a" : "no"] power cell inside.")
		if (power_src)
			to_chat(user, "You can see that it's current charge is [round(power_src.percent())]%")
	else
		if (on)
			to_chat(user, "Current charge: [round(power_src.percent())]%")
