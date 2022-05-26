#define PUDDLE_TRANSFER_THRESHOLD 0.05
#define MAX_PUDDLE_VOLUME 50
#define CIRCLE_PUDDLE_VOLUME 40 //39.26899 technically but this is close enough

var/static/list/burnable_reagents = list(FUEL) //TODO: More types later
var/puddle_text = FALSE

/turf
	var/obj/effect/overlay/puddle/current_puddle = null

var/list/datum/liquid/puddles = list()

/datum/liquid
	var/list/obj/effect/overlay/puddle/liquid_objects = list()
	var/list/obj/effect/overlay/puddle/edge_objects = list()
	var/datum/reagents/reagents = null

/datum/liquid/proc/process()
	for(var/obj/effect/overlay/puddle/L in edge_objects)
		L.spread()

	if(liquid_objects.len == 0)
		qdel(src)

	if(reagents && reagents.volume < PUDDLE_TRANSFER_THRESHOLD)
		qdel(src)

/datum/liquid/New(var/turf/T)
	..()
	puddles += src
	reagents = new(1000)
	reagents.my_liquid = src
	var/obj/effect/overlay/puddle/P = new(T)
	P.controller = src
	liquid_objects += P
	edge_objects += P

/datum/liquid/Destroy()
	puddles -= src
	for(var/obj/O in liquid_objects)
		qdel(O)
		O = null
	qdel(reagents)
	reagents = null
	..()

/client/proc/splash()
	set name = "Create Liquids"
	set category = "Debug"

	if(!usr.client || !usr.client.holder)
		to_chat(usr, "<span class='warning'>You need to be an administrator to access this.</span>")
		return

	var/reagentDatum = input(usr,"Reagent","Insert Reagent","") as text|null
	if(reagentDatum)
		var/reagentAmount = input(usr, "Amount", "Insert Amount", 0) as num
		if(!isnum(reagentAmount))
			return
		if(reagentAmount <= LIQUID_TRANSFER_THRESHOLD)
			return
		var/reagentTemp = input(usr, "Temperature", "Insert Temperature (As Kelvin)", T0C+20) as num
		if(.reagents.add_reagent(reagentDatum, reagentAmount, reagtemp = reagentTemp))
			to_chat(usr, "<span class='warning'>[reagentDatum] doesn't exist.</span>")
			return
		log_admin("[key_name(usr)] added [reagentDatum] with [reagentAmount] units to [A] at [reagentTemp]K temperature.")
		message_admins("[key_name(usr)] added [reagentDatum] with [reagentAmount] units to [A] at [reagentTemp]K temperature.")

	var/turf/T = get_turf(src.mob)
	if(!isturf(T))
		return
	trigger_splash(T, volume)

/turf/proc/create_liquid(reagent_id,volume,temp)
	if(volume <= LIQUID_TRANSFER_THRESHOLD)
		return

	var/datum/liquid/L = new/datum/liquid(src)
	L.reagents.add_reagent(reagent_id,volume,reagtemp = temp)

/client/proc/toggle_puddle_values()
	set name = "Toggle Puddle Values"
	set category = "Debug"

	if(!check_rights(R_DEBUG))
		return
	puddle_text = !puddle_text
	to_chat(usr,"<span class='notice'>Puddle volume value text [puddle_text ? "enabled" : "disabled"]</span>")

/obj/effect/overlay/puddle
	icon = 'icons/effects/puddle.dmi'
	icon_state = "puddle0"
	name = "puddle"
	plane = ABOVE_TURF_PLANE
	layer = PUDDLE_LAYER
	anchored = TRUE
	mouse_opacity = FALSE
	var/turf/turf_on
	var/image/debug_text
	var/datum/liquid/controller

/obj/effect/overlay/puddle/New()
	..()
	turf_on = get_turf(src)
	if(!turf_on)
		qdel(src)
		return

	if(turf_on.current_puddle)
		qdel(turf_on.current_puddle)
	turf_on.current_puddle = src
	debug_text = image(loc = turf_on, layer = ABOVE_LIGHTING_LAYER)
	debug_text.plane = ABOVE_LIGHTING_PLANE
	puddles.Add(src)
	update_icon()

/obj/effect/overlay/puddle/process()
	set waitfor = FALSE
	if(!turf_on || (turf_on.reagents && turf_on.reagents.total_volume < PUDDLE_TRANSFER_THRESHOLD))
		qdel(src)
		return
	if(turf_on.reagents)
		for(var/datum/reagent/R in turf_on.reagents.reagent_list)
			if(R.evaporation_rate)
				turf_on.reagents.remove_reagent(R.id, R.evaporation_rate)
		if(config.puddle_spreading && turf_on.reagents.total_volume > MAX_PUDDLE_VOLUME)
			spread()

/obj/effect/overlay/puddle/proc/spread()
	var/excess_volume = turf_on.reagents.total_volume - MAX_PUDDLE_VOLUME
	var/list/turf/spread_turfs = list()
	for(var/direction in cardinal)
		var/turf/T = get_step(src,direction)
		if(!T)
			log_debug("Puddle reached map edge.")
			continue
		if(!T.reagents && !T.clears_reagents)
			continue
		if(!turf_on.can_leave_liquid(direction)) //Check if this liquid can leave the tile in the direction
			continue
		if(!T.can_accept_liquid(turn(direction,180))) //Check if this liquid can enter the tile
			continue
		spread_turfs += T

	if(!spread_turfs.len)
		return

	var/average_volume = excess_volume / spread_turfs.len //How much would be taken from our tile to fill each
	for(var/datum/reagent/R in turf_on.reagents.reagent_list)
		average_volume = min(R.viscosity, average_volume) //Capped by viscosity
	if(average_volume <= (spread_turfs.len * PUDDLE_TRANSFER_THRESHOLD))
		return //If this is lower than the transfer threshold, break out

	for(var/turf/T in spread_turfs)
		if(!T)
			log_debug("Puddle reached map edge.")
			continue
		if(T.clears_reagents)
			turf_on.reagents.remove_all(average_volume)
			continue
		turf_on.reagents.trans_to(T, average_volume)

/obj/effect/overlay/puddle/getFireFuel() // Copied over from old fuel overlay system and adjusted
	var/total_fuel = 0
	if(turf_on && turf_on.reagents)
		for(var/id in burnable_reagents)
			total_fuel += turf_on.reagents.get_reagent_amount(id)
	return total_fuel

/obj/effect/overlay/puddle/burnFireFuel(var/used_fuel_ratio, var/used_reactants_ratio)
	if(turf_on && turf_on.reagents)
		for(var/id in burnable_reagents)
			// liquid fuel burns 5 times as quick
			turf_on.reagents.remove_reagent(id, turf_on.reagents.get_reagent_amount(id) * used_fuel_ratio * used_reactants_ratio * 5)

/obj/effect/overlay/puddle/Crossed(atom/movable/AM)
	if(turf_on.reagents && (isobj(AM) || ismob(AM))) // Only for reaction_obj and reaction_mob, no misc types.
		if(isliving(AM))
			var/mob/living/L = AM
			if(turf_on.reagents.has_reagent(LUBE))
				L.ApplySlip(TURF_WET_LUBE, turf_on.reagents.get_reagent_amount(LUBE))
			else if(turf_on.reagents.has_any_reagents(MILDSLIPPABLES))
				L.ApplySlip(TURF_WET_WATER, turf_on.reagents.get_reagent_amounts(MILDSLIPPABLES))
			var/list/limbs_to_hit = list(LIMB_LEFT_FOOT,LIMB_RIGHT_FOOT) // Only targeting feet here.
			if(L.lying) // Unless lying down.
				switch(L.dir)
					if(SOUTH) // On their back, no mouth or eyes, everything else.
						limbs_to_hit = ALL_NORMAL_LIMBS
					if(NORTH) // On their front, everything.
						limbs_to_hit = ALL_LIMBS
					if(EAST) // On their side, left limbs.
						limbs_to_hit = LEFT_LIMBS
					if(WEST) // On their side, right limbs.
						limbs_to_hit = RIGHT_LIMBS
			turf_on.reagents.reaction(L, volume_multiplier = 0.1, zone_sels = limbs_to_hit)
		else
			turf_on.reagents.reaction(AM, volume_multiplier = 0.1)
		turf_on.reagents.remove_all(turf_on.reagents.total_volume/10)

	else
		return ..()

// Overly gimmicky proc for if we want player controlled puddles for whatever reason
/obj/effect/overlay/puddle/Move(NewLoc, Dir = 0, step_x = 0, step_y = 0, glide_size_override = 0)
	if(turf_on && turf_on.reagents)
		var/lowest_viscosity = turf_on.reagents.total_volume
		for(var/datum/reagent/R in turf_on.reagents.reagent_list)
			lowest_viscosity = min(R.viscosity, lowest_viscosity) //Capped by viscosity
		turf_on.reagents.trans_to(NewLoc, lowest_viscosity)
		if(isturf(NewLoc))
			var/turf/T = NewLoc
			if(T.reagents && T.reagents.total_volume >= MAX_PUDDLE_VOLUME)
				qdel(T.current_puddle)
				T.current_puddle = src
				turf_on = NewLoc
				return ..()

/obj/effect/overlay/puddle/Destroy()
	for(var/client/C in admins)
		C.images -= debug_text
	if(turf_on && turf_on.reagents)
		turf_on.reagents.clear_reagents()
	puddles.Remove(src)
	turf_on.maptext = ""
	turf_on.current_puddle = null
	..()

/obj/effect/overlay/puddle/update_icon()
	for(var/client/C in admins)
		C.images -= debug_text
	if(turf_on && turf_on.reagents && turf_on.reagents.reagent_list.len)
		color = mix_color_from_reagents(turf_on.reagents.reagent_list,TRUE)
		alpha = mix_alpha_from_reagents(turf_on.reagents.reagent_list,TRUE)
		var/puddle_volume = turf_on.reagents.total_volume
		// Absolute scaling with volume, Scale() would give relative.
		transform = matrix(min(1, puddle_volume / CIRCLE_PUDDLE_VOLUME), 0, 0, 0, min(1, puddle_volume / CIRCLE_PUDDLE_VOLUME), 0)
		if(puddle_text)
			var/round = 1
			if(puddle_volume < 1000)
				round = 0.1
			if(puddle_volume < 100)
				round = 0.01
			if(puddle_volume < 10)
				round = 0.001
			debug_text.maptext = "<span class = 'center maptext black_outline'>[round(puddle_volume, round)]</span>"
			for(var/client/C in admins)
				C.images += debug_text
		relativewall()
	else // Sanity
		qdel(src)

/obj/effect/overlay/puddle/relativewall()
	// Circle value as to have some breathing room
	if(turf_on && turf_on.reagents && turf_on.reagents.total_volume >= CIRCLE_PUDDLE_VOLUME)
		var/junction=findSmoothingNeighbors()
		icon_state = "puddle[junction]"
	else
		icon_state = "puddle0"

/obj/effect/overlay/puddle/canSmoothWith()
	var/static/list/smoothables = list(
		/obj/effect/overlay/puddle,
	)
	return smoothables

/obj/effect/overlay/puddle/isSmoothableNeighbor(var/obj/effect/overlay/puddle/A)
	if(istype(A) && A.turf_on && A.turf_on.reagents && A.turf_on.reagents.total_volume < CIRCLE_PUDDLE_VOLUME)
		return

	return ..()

/turf/proc/can_accept_liquid(from_direction)
	return 0
/turf/proc/can_leave_liquid(from_direction)
	return 0

/turf/space/can_accept_liquid(from_direction)
	return 1
/turf/space/can_leave_liquid(from_direction)
	return 1

/turf/simulated/floor/can_accept_liquid(from_direction)
	for(var/obj/structure/window/W in src)
		if(W.is_fulltile)
			return 0
		if(W.dir & from_direction)
			return 0
	for(var/obj/O in src)
		if(!O.liquid_pass())
			return 0
	return 1

/turf/simulated/floor/can_leave_liquid(to_direction)
	for(var/obj/structure/window/W in src)
		if(W.is_fulltile)
			return 0
		if(W.dir & to_direction)
			return 0
	for(var/obj/O in src)
		if(!O.liquid_pass())
			return 0
	return 1

/turf/simulated/wall/can_accept_liquid(from_direction)
	return 0
/turf/simulated/wall/can_leave_liquid(from_direction)
	return 0

/obj/proc/liquid_pass()
	return 1

/obj/machinery/door/liquid_pass()
	return !density

/obj/effect/overlay/puddle/mapping
	var/reagent_type = ""
	var/volume = 50

/obj/effect/overlay/puddle/mapping/initialize()
	if(turf_on && turf_on.reagents)
		turf_on.reagents.add_reagent(reagent_type,volume)

/obj/effect/overlay/puddle/mapping/water
	reagent_type = WATER

/obj/effect/overlay/puddle/mapping/fuel
	reagent_type = FUEL
