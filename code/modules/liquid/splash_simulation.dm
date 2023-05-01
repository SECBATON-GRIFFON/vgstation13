#define PUDDLE_TRANSFER_THRESHOLD 0.05
#define MAX_PUDDLE_VOLUME 50
#define CIRCLE_PUDDLE_VOLUME 40 //39.26899 technically but this is close enough
#define DEBUG_LIQUIDS
//#define DEBUG_LIQUIDS_SPREAD

var/static/list/burnable_reagents = list(FUEL) //TODO: More types later
var/puddle_text = FALSE

/turf
	var/datum/liquid/liquid = null
	var/obj/effect/liquid/current_puddle = null

/datum/liquid
	var/list/obj/effect/liquid/liquid_objects = list()
	var/list/obj/effect/liquid/edge_objects = list()
	var/datum/reagents/reagents = null

/datum/liquid/New(var/turf/T)
	..()
	puddles += src
	reagents = new/datum/reagents(1000) // For an entire cubic space, 1000 units
	reagents.my_atom = src
	if(!T.liquid)
		T.liquid = src
	if(!T.current_puddle)
		new /obj/effect/liquid(T)

/datum/liquid/Destroy()
	puddles -= src
	for(var/obj/O in liquid_objects)
		QDEL_NULL(O)
	QDEL_NULL(reagents)
	..()

/datum/liquid/proc/process()
	if(!reagents || !liquid_objects.len)
#ifdef DEBUG_LIQUIDS
		log_debug("Liquid deleted due to lack of valid reagents or objects")
#endif
		qdel(src)
		return

	if(reagents.total_volume < (PUDDLE_TRANSFER_THRESHOLD * liquid_objects.len))
#ifdef DEBUG_LIQUIDS
		log_debug("Liquid deleted due to low volume. ([reagents.total_volume]u, [liquid_objects.len] objects)")
#endif
		qdel(src)
		return

	if(liquid_objects.len > 1 && reagents.total_volume < (MAX_PUDDLE_VOLUME * liquid_objects.len))
		return split()

	for(var/datum/reagent/R in reagents.reagent_list)
		if(R.evaporation_rate)
			reagents.remove_reagent(R.id, R.evaporation_rate*(SS_WAIT_LIQUID/20))

	if(config.puddle_spreading && reagents.total_volume > (MAX_PUDDLE_VOLUME*liquid_objects.len))
#ifdef DEBUG_LIQUIDS
		var/spread_time = world.time
#endif
		for(var/obj/effect/liquid/L in edge_objects)
			L.spread()
#ifdef DEBUG_LIQUIDS
		spread_time = (world.time - spread_time)/10
		log_debug("Liquid spread took [spread_time] seconds.")
#endif

	reagents.maximum_volume = 1000 * liquid_objects.len

/datum/liquid/proc/merge(var/datum/liquid/other)
#ifdef DEBUG_LIQUIDS
	log_debug("Liquid ([reagents.total_volume]u, [liquid_objects.len] objects) to merge with another ([other.reagents.total_volume]u, [other.liquid_objects.len] objects)")
#endif
	if(reagents)
		if(reagents.total_volume < (MAX_PUDDLE_VOLUME * liquid_objects.len))
			return
		for(var/obj/effect/liquid/L in other.liquid_objects)
			if(L.turf_on)
				L.turf_on.liquid = src
			liquid_objects += L
			if(L in other.edge_objects)
				edge_objects += L
		reagents.maximum_volume = 1000 * liquid_objects.len
		other.reagents.trans_to_holder(src.reagents)
		other.liquid_objects.Cut()
#ifdef DEBUG_LIQUIDS
		log_debug("Liquid deleted due to merge with other. (now [reagents.total_volume]u, [liquid_objects.len] objects)")
#endif
		qdel(other)

/datum/liquid/proc/split()
	if(reagents.total_volume >= MAX_PUDDLE_VOLUME * liquid_objects.len || liquid_objects.len <= 1)
		return
#ifdef DEBUG_LIQUIDS
	log_debug("Liquid ([reagents.total_volume]u, [liquid_objects.len] objects) deleted due to split from low volume")
#endif
	for(var/obj/effect/liquid/LO in liquid_objects)
		LO.turf_on.liquid = new(LO.turf_on)
		reagents.trans_to_holder(LO.turf_on.liquid.reagents, MAX_PUDDLE_VOLUME)
	liquid_objects.Cut()
	qdel(src)

/datum/liquid/on_reagent_change()
	for(var/obj/effect/liquid/P in liquid_objects)
		if(config.puddle_reactions)
			reagents.reaction(P.turf_on, volume_multiplier = 0)
		P.update_icon()

/turf/proc/add_to_liquid(var/reagent, var/amount, var/list/data=null, var/reagtemp = T0C+20)
	if(amount <= PUDDLE_TRANSFER_THRESHOLD)
		return

	if(!liquid)
		liquid = new(src)
	return liquid.reagents.add_reagent(reagent,amount,data,reagtemp)

/turf/proc/trans_from_source(var/datum/reagents/from, var/amount=1, var/multiplier=1, var/preserve_data=1)
	if(amount <= PUDDLE_TRANSFER_THRESHOLD)
		return

	if(!liquid)
		liquid = new(src)
	return from.trans_to_holder(liquid.reagents, amount, multiplier, preserve_data)

/client/proc/toggle_puddle_values()
	set name = "Toggle Puddle Values"
	set category = "Debug"

	if(!check_rights(R_DEBUG))
		return
	puddle_text = !puddle_text
	to_chat(usr,"<span class='notice'>Puddle volume value text [puddle_text ? "enabled" : "disabled"]</span>")

/obj/effect/liquid
	icon = 'icons/effects/puddle.dmi'
	icon_state = "puddle0"
	name = "puddle"
	plane = ABOVE_TURF_PLANE
	layer = PUDDLE_LAYER
	anchored = TRUE
	mouse_opacity = FALSE
	var/turf/turf_on
	var/image/debug_text

/obj/effect/liquid/New()
	..()
	turf_on = get_turf(src)
	if(!turf_on || !turf_on.liquid || !turf_on.liquid.reagents)
		log_debug("Puddle attempted creation at [turf_on ? "[turf_on] ([turf_on.x],[turf_on.y],[turf_on.z])" : "unknown turf"] and failed[turf_on && turf_on.liquid ? " at reagent creation" : " at liquid creation"].")
		qdel(src)
		return

	debug_text = image(loc = turf_on, layer = ABOVE_LIGHTING_LAYER)
	debug_text.plane = ABOVE_LIGHTING_PLANE
	turf_on.liquid.liquid_objects += src
	if(turf_on.current_puddle)
		qdel(turf_on.current_puddle)
	turf_on.current_puddle = src
	for(var/direction in cardinal)
		var/turf/T = get_step(src,direction)
		if(!T.current_puddle)
			turf_on.liquid.edge_objects += src
			break
	update_icon()

/obj/effect/liquid/Destroy()
	for(var/client/C in admins)
		C.images -= debug_text
	if(turf_on.liquid)
		if(turf_on.liquid.reagents?.total_volume)
			turf_on.liquid.reagents.remove_all(min(turf_on.liquid.reagents.total_volume,50))
		turf_on.liquid.liquid_objects -= src
		if(src in turf_on.liquid.edge_objects)
			turf_on.liquid.edge_objects -= src
		turf_on.liquid = null
	for(var/direction in cardinal)
		var/turf/T = get_step(src,direction)
		if(T.current_puddle && T.liquid)
			T.liquid.edge_objects += T.current_puddle
			break
	turf_on.maptext = ""
	turf_on.current_puddle = null
	..()

/obj/effect/liquid/proc/spread()
	if(!turf_on || !turf_on.liquid || !turf_on.liquid.reagents)
		log_debug("Puddle attempted spread begin at [turf_on ? "[turf_on] ([turf_on.x],[turf_on.y],[turf_on.z])" : "unknown turf"] and failed.")
		qdel(src)
		return
	var/excess_volume = turf_on.liquid.reagents.total_volume - (MAX_PUDDLE_VOLUME*turf_on.liquid.liquid_objects.len)
#ifdef DEBUG_LIQUIDS_SPREAD
	log_debug("Liquid has excess volume of [excess_volume]u. ([turf_on.liquid.reagents.total_volume]u, [turf_on.liquid.liquid_objects.len] objects)")
#endif
	var/list/turf/spread_turfs = list()
	for(var/direction in cardinal)
		var/turf/T = get_step(src,direction)
		if(!T)
			log_debug("Puddle reached map edge at [turf_on]. ([turf_on.x],[turf_on.y],[turf_on.z])")
			continue
		if(!turf_on.can_leave_liquid(direction)) //Check if this liquid can leave the tile in the direction
			continue
		if(!T.can_accept_liquid(opposite_dirs[direction])) //Check if this liquid can enter the tile
			continue
		if(T.liquid && T.liquid == src.turf_on.liquid)
			continue
		spread_turfs += T
		if(!(src in turf_on.liquid.edge_objects))
			turf_on.liquid.edge_objects += src

	if(!spread_turfs.len)
		if(turf_on.liquid && (src in turf_on.liquid.edge_objects))
			turf_on.liquid.edge_objects -= src
		return

	var/average_volume = excess_volume / spread_turfs.len //How much would be taken from our tile to fill each
#ifdef DEBUG_LIQUIDS_SPREAD
	log_debug("Liquid has average spread volume of [average_volume]u before viscosity checks. ([turf_on.liquid.reagents.total_volume]u, [turf_on.liquid.liquid_objects.len] objects)")
#endif
	for(var/datum/reagent/R in turf_on.liquid.reagents.reagent_list)
		average_volume = min(R.viscosity, average_volume) //Capped by viscosity
#ifdef DEBUG_LIQUIDS_SPREAD
	log_debug("Liquid has average spread volume of [average_volume]u after viscosity checks. ([turf_on.liquid.reagents.total_volume]u, [turf_on.liquid.liquid_objects.len] objects)")
#endif
	if(average_volume <= (spread_turfs.len * PUDDLE_TRANSFER_THRESHOLD))
		return //If this is lower than the transfer threshold, break out

	for(var/turf/T in spread_turfs)
		if(!T)
			log_debug("Puddle reached map edge at [turf_on]. ([turf_on.x],[turf_on.y],[turf_on.z])")
			continue
		if(T.liquid && T.liquid == turf_on.liquid)
			continue
		if(T.clears_reagents)
			turf_on.liquid.reagents.remove_all(average_volume)
			continue
		if(T.liquid && T.liquid != turf_on.liquid && ((T.liquid.reagents.total_volume/T.liquid.liquid_objects.len) > MAX_PUDDLE_VOLUME))
			turf_on.liquid.merge(T.liquid)
			continue
		T.trans_from_source(turf_on.liquid.reagents, average_volume)
		if(T.liquid && T.liquid != turf_on.liquid && ((T.liquid.reagents.total_volume/T.liquid.liquid_objects.len) > MAX_PUDDLE_VOLUME))
			turf_on.liquid.merge(T.liquid)
#ifdef DEBUG_LIQUIDS_SPREAD
	log_debug("Liquid is now [turf_on.liquid.reagents.total_volume]u, [turf_on.liquid.liquid_objects.len] objects after spread.")
#endif

/obj/effect/liquid/getFireFuel() // Copied over from old fuel overlay system and adjusted
	var/total_fuel = 0
	if(turf_on.liquid && turf_on.liquid.reagents)
		for(var/id in burnable_reagents)
			total_fuel += turf_on.liquid.reagents.get_reagent_amount(id)
	return total_fuel

/obj/effect/liquid/burnFireFuel(var/used_fuel_ratio, var/used_reactants_ratio)
	if(turf_on.liquid && turf_on.liquid.reagents)
		for(var/id in burnable_reagents)
			// liquid fuel burns 5 times as quick
			turf_on.liquid.reagents.remove_reagent(id, turf_on.liquid.reagents.get_reagent_amount(id) * used_fuel_ratio * used_reactants_ratio * 5)

/obj/effect/liquid/Crossed(atom/movable/AM)
	if(turf_on.liquid.reagents && (isobj(AM) || ismob(AM))) // Only for reaction_obj and reaction_mob, no misc types.
		if(isliving(AM))
			var/mob/living/L = AM
			if(turf_on.liquid.reagents.has_reagent(LUBE))
				L.ApplySlip(TURF_WET_LUBE, turf_on.liquid.reagents.get_reagent_amount(LUBE))
			else if(turf_on.liquid.reagents.has_any_reagents(MILDSLIPPABLES))
				L.ApplySlip(TURF_WET_WATER, turf_on.liquid.reagents.get_reagent_amounts(MILDSLIPPABLES))
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
			turf_on.liquid.reagents.reaction(L, volume_multiplier = 0.1, zone_sels = limbs_to_hit)
		else
			turf_on.liquid.reagents.reaction(AM, volume_multiplier = 0.1)
		turf_on.liquid.reagents.remove_all(turf_on.liquid.reagents.total_volume/10)

	else
		return ..()

/obj/effect/liquid/Move(NewLoc, Dir = 0, step_x = 0, step_y = 0, glide_size_override = 0)
	return

/obj/effect/liquid/update_icon()
	for(var/client/C in admins)
		C.images -= debug_text
	if(turf_on?.liquid?.reagents)
		if(turf_on.liquid.reagents.reagent_list.len)
			color = mix_color_from_reagents(turf_on.liquid.reagents.reagent_list,TRUE)
			alpha = mix_alpha_from_reagents(turf_on.liquid.reagents.reagent_list,TRUE)
		var/puddle_volume = turf_on.liquid.reagents.total_volume
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
			debug_text.maptext = "<span class = 'center maptext black_outline'>[round(puddle_volume, round)][(src in turf_on.liquid.edge_objects) ? "<br>(EDGE)" : ""]</span>"
			for(var/client/C in admins)
				C.images += debug_text
		if(turf_on.liquid.reagents.total_volume >= CIRCLE_PUDDLE_VOLUME)
			relativewall()
			relativewall_neighbours()
	else // Sanity
		log_debug("Puddle attempted icon update at [turf_on ? "[turf_on] ([turf_on.x],[turf_on.y],[turf_on.z])" : "unknown turf"] and failed.")
		qdel(src)

/obj/effect/liquid/relativewall()
	// Circle value as to have some breathing room
	if(turf_on.liquid?.reagents?.total_volume >= CIRCLE_PUDDLE_VOLUME)
		var/junction=findSmoothingNeighbors()
		icon_state = "puddle[junction]"
	else
		icon_state = "puddle0"

/obj/effect/liquid/canSmoothWith()
	var/static/list/smoothables = list(
		/turf,/obj
	)
	return smoothables

/obj/effect/liquid/isSmoothableNeighbor(atom/A)
	if(isturf(A))
		var/turf/T = A
		if(!T.can_accept_liquid(get_dir(A,src)) || !T.can_leave_liquid(get_dir(src,A)) || (T.liquid?.reagents?.total_volume >= CIRCLE_PUDDLE_VOLUME))
			return ..()
	else if(istype(A,/obj)) // This was somehow letting all movable atoms count when isobj(), THANKS BYOND
		var/obj/O = A
		if(!O.liquid_pass())
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

/obj/effect/liquid/mapping
	var/reagent_type = ""
	var/volume = 50

/obj/effect/liquid/mapping/New()
	var/turf/T = get_turf(src)
	T.liquid = new(T)
	..()

/obj/effect/liquid/mapping/initialize()
	turf_on.add_to_liquid(reagent_type,volume)

/obj/effect/liquid/mapping/water
	reagent_type = WATER

/obj/effect/liquid/mapping/fuel
	reagent_type = FUEL
