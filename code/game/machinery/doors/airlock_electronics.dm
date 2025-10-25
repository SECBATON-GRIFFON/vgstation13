//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

/obj/item/weapon/circuitboard/airlock
	name = "\proper access electronics"
	desc = "A circuit board used to operate access controls on various machinery."
	board_type= OTHER
	icon = 'icons/obj/doors/door_assembly.dmi'
	icon_state = "door_electronics"
	w_class = W_CLASS_SMALL //It should be tiny! -Agouri
	starting_materials = list(MAT_IRON = 50, MAT_GLASS = 50)
	w_type = RECYK_ELECTRONIC
	melt_temperature = MELTPOINT_SILICON
	//origin_tech = Tc_PROGRAMMING + "=2"

	req_access = list(access_engine_minor)

	var/list/conf_access = null
	var/one_access = 0 //if set to 1, door would receive req_one_access instead of req_access
	var/dir_access = 0 //if set to a dir, door would use req_access_dir
	var/access_nodir = 1 //if set to 1, all access if not in dir, otherwise none
	var/last_configurator = null
	var/locked = 1
	var/installed = 0

	// Allow dicking with it while it's on the floor.
/obj/item/weapon/circuitboard/airlock/attack_robot(mob/user as mob)
	if(isMoMMI(user))
		return ..()
	attack_self(user)
	return 1

/obj/item/weapon/circuitboard/airlock/attackby(obj/item/W as obj, mob/user as mob)
	if(issolder(W))
		var/obj/item/tool/solder/S = W
		if(icon_state == "door_electronics_smoked")
			if(S.do_solder(user, src,4 SECONDS,4))
				S.playtoolsound(loc, 100)
				icon_state = "door_electronics"
				to_chat(user, "<span class='notice'>You repair the blown fuses on the circuitboard.</span>")

/obj/item/weapon/circuitboard/airlock/attack_self(mob/user as mob)
	if (!ishigherbeing(user) && !isrobot(user))
		return ..()

	// Can't manipulate it when broken (e.g. emagged)
	if (icon_state == "door_electronics_smoked")
		return
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.getBrainLoss() >= 60)
			return

	interact(user)

/obj/item/weapon/circuitboard/airlock/interact(mob/user as mob)
	var/datum/browser/popup = new(user, "airlock_electronics", "Access Control", 640, 480)
	popup.set_content(get_dat(user))
	popup.open()

/obj/item/weapon/circuitboard/airlock/proc/get_dat(mob/user)
	. = ""

	if (last_configurator)
		. += "Operator: [last_configurator]<br>"

	if (locked)
		if(isrobot(user))
			. += "<a href='?src=\ref[src];login=1'>Log In</a><hr>"
		else
			. += "<a href='?src=\ref[src];login=1'>Set access</a><hr>"
	else
		. += "<a href='?src=\ref[src];logout=1'>Finish</a><hr>"

		. += "Access requirement is set to "
		. += one_access ? "<a style='background: green' href='?src=\ref[src];one_access=1'>ONE</a><hr>" : "<a style='background: red' href='?src=\ref[src];one_access=1'>ALL</a><hr>"

		. += "Access direction is set to "
		. += "<a href='?src=\ref[src];access_dir=1'>[dir2arrow(dir_access)]</a><hr>"

		if(dir_access)
			. += "Accessing while not in access direction is set to "
			. += access_nodir ? "<a style='background: green' href='?src=\ref[src];notdir=1'>TRUE</a><hr>" : "<a style='background: red' href='?src=\ref[src];notdir=1'>FALSE</a><hr>"

		. += conf_access == null ? "<font style='background: red'>All</font><br>" : "<a href='?src=\ref[src];access=all'>All</a><br>"

		. += "<br>"

		. += "<div style='clear: both'>"

		for(var/i = 1; i <= 7; i++)
			. += "<div style='float: left'>"
			. += "<b>[get_region_accesses_name(i)]</b><br>"
			for(var/access in get_region_accesses(i))
				var/aname = get_access_desc(access)

				if (!conf_access || !conf_access.len || !(access in conf_access))
					. += "<a href='?src=\ref[src];access=[access]'>[aname]</a><br>"
				else if(one_access)
					. += "<a style='background: green' href='?src=\ref[src];access=[access]'>[aname]</a><br>"
				else
					. += "<a style='background: red' href='?src=\ref[src];access=[access]'>[aname]</a><br>"
			. += "<br>"
			. += "</div>"

		. += "</div>"

/obj/item/weapon/circuitboard/airlock/Topic(href, href_list)
	if(..())
		return 1 //Its not as though this does ANYTHING
	if(!Adjacent(usr) || usr.incapacitated() || (!ishigherbeing(usr) && !isrobot(usr)) || icon_state == "door_electronics_smoked" || installed)
		return

	if(href_list["login"])
		if(ishuman(usr))
			var/obj/item/weapon/card/id/I = usr.get_id_card()
			if(istype(I) && src.check_access(I))
				src.locked = 0
				src.last_configurator = I.registered_name
		if(isrobot(usr))
			src.locked = 0
			src.last_configurator = usr.name

	if(locked)
		to_chat(usr, "<span class='warning'>Access denied.</span>")
		return

	if(href_list["logout"])
		locked = 1

	if(href_list["one_access"])
		one_access = !one_access

	if(href_list["access"])
		toggle_access(href_list["access"])

	if(href_list["access_dir"])
		var/setdir = dir_access
		var/static/list/allowed_dirs = list("None","NORTH","SOUTH","EAST","WEST")
		setdir = input(usr,"Enter a new access dir", "Access direction") as null|anything in allowed_dirs
		if(setdir && setdir != "None")
			dir_access = text2dir(setdir)
		else
			dir_access = 0

	if(href_list["notdir"])
		access_nodir = !access_nodir

	interact(usr)

/obj/item/weapon/circuitboard/airlock/proc/toggle_access(var/acc)
	if (acc == "all")
		conf_access = null
	else
		var/req = text2num(acc)

		if (conf_access == null)
			conf_access = list()

		if (!(req in conf_access))
			conf_access += req
		else
			conf_access -= req
			if (!conf_access.len)
				conf_access = null

/obj/item/weapon/circuitboard/airlock/dna
	name = "\proper DNA access electronics"
	desc = "A circuit board used to operate access and DNA controls on various machinery."
	icon_state = "door_electronics"
	var/datum/dna2/record/buf = null
	var/list/conf_ui = null
	var/list/conf_se = null

/obj/item/weapon/circuitboard/airlock/dna/New()
	. = ..()
	buf = new
	buf.dna = new

/obj/item/weapon/circuitboard/airlock/dna/attackby(obj/item/W, mob/user)
	. = ..()
	if(istype(W,/obj/item/weapon/disk/data))
		var/obj/item/weapon/disk/data/D = W
		if(D.buf)
			qdel(buf)
			buf = D.buf.Clone()
			to_chat(user,"<span class='notice'>DNA data copied from \the [D] to \the [src].</span>")
		else
			to_chat(user,"<span class='warning'>This [D.name] has no DNA data on it.</span>")

/obj/item/weapon/circuitboard/airlock/dna/get_dat(mob/user)
	. = ..()

	if(!locked)
		. += "DNA ACCESS<br><br>Unique identifiers:<br>"

		for(var/UI in buf.dna.UI)
			. += "<font style = 'background: green'>[UI]</font><br>"

		. += "<br>Structural enzymes:<br>"

		for(var/SE in buf.dna.SE)
			. += "<font style = 'background: green'>[SE]</font><br>"
