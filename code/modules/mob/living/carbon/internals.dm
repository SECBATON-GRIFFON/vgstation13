/mob/living/carbon/proc/has_breathing_mask()
	return is_wearing_item(/obj/item/clothing/mask, slot_wear_mask)

/mob/living/carbon/proc/internals_candidates() //These are checked IN ORDER.
	return get_all_slots() + held_items

/mob/living/carbon/human/internals_candidates() //Humans have a lot of slots, so let's give priority to some of them
	var/list/priority = list(s_store, back, belt, l_store, r_store)
	if(wear_suit && isrig(wear_suit)) //Don't forget the rigsuit!
		var/obj/item/clothing/suit/space/rig/rig = wear_suit
		if(rig.T)
			priority += rig.T
	return priority | get_all_slots() | held_items //| operator ensures there are no duplicates

/mob/living/carbon/proc/get_internals_tank()
	for(var/obj/item/weapon/tank/T in internals_candidates())
		//We found a tank!
		if(istype(T, /obj/item/weapon/tank/jetpack)) //Oh... But it's a jetpack... We'll use it if we have to, but let's see if we find something better first
			if(!.) //We already had another jetpack
				. = T
			continue
		else //It's the real deal!
			return T

// Set internals on or off.
/mob/living/carbon/proc/toggle_internals(var/mob/living/user, var/obj/item/weapon/tank/T)
	if(user.incapacitated())
		return

	if(internal)
		internal.add_fingerprint(user)
		equip_internals(null)
		if(user != src)
			if(!user.isGoodPickpocket())
				visible_message("<span class='warning'>\The [user] shuts off \the [src]'s internals!</span>")
			user.attack_log += text("\[[time_stamp()]\] <font color='red'>Has disabled [src.name]'s ([src.ckey]) internals.</font>")
			src.attack_log += text("\[[time_stamp()]\] <font color='red'>Internals disabled by [user.name] ([user.ckey]).</font>")
			log_attack("[user.name] ([user.ckey]) has disabled [src.name]'s ([src.ckey]) internals.")
		else
			to_chat(user, "<span class='notice'>No longer running on internals.</span>")
		return 1
	else
		if(!has_breathing_mask())
			if(user != src)
				to_chat(user, "<span class='warning'>\The [src] is not wearing a breathing mask.</span>")
			else
				to_chat(user, "<span class='warning'>You are not wearing a breathing mask.</span>")
			return
		if(!T || !T.Adjacent()) //We can be given a specific tank to connect to
			T = get_internals_tank()
			if(!T)
				var/breathes = OXYGEN
				if(ishuman(src))
					var/mob/living/carbon/human/H = src
					breathes = H.species.breath_type
				if(user != src)
					to_chat(user, "<span class='warning'>\The [src] does not have \an [breathes] tank.</span>")
				else
					to_chat(user, "<span class='warning'>You don't have \an [breathes] tank.</span>")
				return
		T.add_fingerprint(user)
		equip_internals(T)
		if(user != src)
			var/gas_contents = T.air_contents.english_contents_list()
			if(!user.isGoodPickpocket())
				to_chat(user, "<span class='notice'>\The [user] has enabled [src]'s internals.</span>")
			user.attack_log += text("\[[time_stamp()]\] <font color='red'>Has enabled [src.name]'s ([src.ckey]) internals (Gas contents: [gas_contents]).</font>")
			src.attack_log += text("\[[time_stamp()]\] <font color='red'>Internals enabled by [user.name] ([user.ckey]) (Gas contents: [gas_contents]).</font>")
			log_attack("[user.name] ([user.ckey]) has enabled [src.name]'s ([src.ckey]) internals (Gas contents: [gas_contents]).")
		else
			to_chat(src, "<span class='notice'>You are now running on internals from \the [T].</span>")
		return 1

/mob/living/carbon/proc/equip_internals(obj/item/weapon/tank/tank)
	internal = tank
	update_internals()

/mob/living/carbon/proc/update_internals()
	if(internals)
		internals.icon_state = "internal-oxy-[internal ? "1" : "0"]"

/mob/living/carbon/human/update_internals()
	if(internals)
		var/breath_string = "oxy"
		if(species)
			switch(species.breath_type)
				if(GAS_NITROGEN)
					breath_string = "nitro"
				if(GAS_PLASMA)
					breath_string = "plasma"
		internals.icon_state = "internal-[breath_string]-[internal ? "1" : "0"]"

/mob/living/carbon
	var/lung_damages = FALSE

/mob/living/carbon/proc/breathe()
	if(!needs_to_breathe())
		return
	if(nobreath)
		nobreath--
		return

	var/datum/organ/internal/lungs/L = get_lungs()
	if(L)
		L.process() //Ideally lungs would handle breathing, but right now we're just sanitizing

	var/datum/gas_mixture/environment = loc.return_air()
	var/datum/gas_mixture/breath
	//HACK NEED CHANGING LATER
	if(health < config.health_threshold_crit || !L)
		losebreath++
	if(losebreath > 0) //Suffocating so do not take a breath
		losebreath--
		if(prob(10)) //Gasp per 10 ticks? Sounds about right.
			spawn()
				emote("gasp")
		if(istype(loc, /obj/))
			var/obj/location_as_object = loc
			location_as_object.handle_internal_lifeform(src, 0)
	else
		//First, check for air from internal atmosphere (using an air tank and mask generally)
		breath = get_breath_from_internal(BREATH_VOLUME) // Super hacky -- TLE
		//breath = get_breath_from_internal(0.5) // Manually setting to old BREATH_VOLUME amount -- TLE

		//No breath from internal atmosphere so get breath from location
		if(!breath)
			if(check_breath_block())
				// Breathing blocked
			else if(isobj(loc))
				var/obj/location_as_object = loc
				breath = location_as_object.handle_internal_lifeform(src, BREATH_VOLUME)
			else if(isturf(loc))
				if(environment)
					breath = environment.remove_volume(CELL_VOLUME * BREATH_PERCENTAGE)

				if(lung_damages)
					if(!breath || breath.total_moles < BREATH_MOLES / 5 || breath.total_moles > BREATH_MOLES * 5)
						if(prob(20))
							L.take_damage(1,1)
						if(!is_lung_ruptured() && L.damage > 2)
							var/chance_break = (L.damage / L.min_broken_damage)*100
							if(prob(chance_break))
								rupture_lung()

				if(breath && !check_breath_block(TRUE))
					for(var/obj/effect/smoke/chem/smoke in view(1, src))
						if(smoke.reagents && smoke.reagents.total_volume)
							smoke.reagents.reaction(src, INGEST, amount_override = min(smoke.reagents.total_volume,10)/(smoke.reagents.reagent_list.len))
							spawn(5)
								if(smoke && smoke.reagents)
									smoke.reagents.copy_to(src, 10)
							break

					breath_airborne_diseases()

		else
			if(istype(loc, /obj/))
				var/obj/location_as_object = loc
				location_as_object.handle_internal_lifeform(src, 0)

	if(breath && wear_mask && wear_mask.heat_conductivity < 1)
		var/temp_difference = bodytemperature - breath.temperature
		var/temp_change = (1 - wear_mask.heat_conductivity) * temp_difference
		breath.temperature += temp_change

	handle_breath(breath)

	handle_species_environment(environment, src)

	if(breath)
		loc.assume_air(breath)
/*
		//Spread some viruses while we are at it
		if(virus2 && virus2.len > 0)
			//if(get_infection_chance(src))//checking our own infection protections, so we don't spread an airborne virus if we're wearing internals
			//	for(var/mob/living/M in range(1,src))
			//		if(can_be_infected(M))
			//			spread_disease_to(src,M)
*/

/mob/living/carbon/proc/needs_to_breathe()
	if(flags & INVULNERABLE)
		return FALSE
	if(reagents.has_any_reagents(LEXORINS))
		return FALSE
	if(M_NO_BREATH in mutations)
		return FALSE //No breath mutation means no breathing.
	if(istype(loc, /obj/machinery/atmospherics/unary/cryo_cell)) //This is an annoying hack given that cryo cells are supposed to be oxygenated, but fuck it
		return FALSE
	return TRUE

/mob/living/carbon/proc/handle_species_environment(var/datum/gas_mixture/environment)
	return

/mob/living/carbon/proc/check_breath_block(var/smoke_only = FALSE)
	return

/mob/living/carbon/proc/get_lungs()
	return

/mob/living/carbon/proc/handle_breath(var/datum/gas_mixture/breath)
	return
