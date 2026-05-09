//Refer to life.dm for caller
/mob/living/carbon/human
	lung_damages = TRUE

/mob/living/carbon/human/get_breath_from_internal(volume_needed)
	if(internal)
		if(!contents.Find(internal))
			if(wear_suit && isrig(wear_suit)) //But what if he's wearing a rigsuit?
				var/obj/item/clothing/suit/space/rig/rig = wear_suit
				if(!rig.T) //But if the rig has no internal tank...
					internal = null
			else
				internal = null
		if(!wear_mask || !(wear_mask.clothing_flags & MASKINTERNALS))
			internal = null
		update_internals()
		if(internal)
			return internal.remove_air_volume(volume_needed)
	return null

/mob/living/carbon/human/get_lungs()
	return internal_organs_by_name["lungs"]

/mob/living/carbon/human/needs_to_breathe()
	if(undergoing_hypothermia() == PROFOUND_HYPOTHERMIA) // we're not breathing. see handle_hypothermia.dm for details.
		return FALSE
	if (species && (species.flags & NO_BREATHE))
		return FALSE
	return ..()

/mob/living/carbon/human/handle_species_environment(var/datum/gas_mixture/environment)
	if(species)
		species.handle_environment(environment, src)

/mob/living/carbon/human/check_breath_block(var/smoke_only = FALSE)
	var/list/blockers = list(wear_mask,glasses,head)
	for (var/item in blockers)
		var/obj/item/I = item
		if (!istype(I))
			continue
		if(smoke_only)
			if (I.clothing_flags & BLOCK_GAS_SMOKE_EFFECT)
				return TRUE
		else
			if (I.clothing_flags & BLOCK_GAS_SMOKE_EFFECT)
				return TRUE
	return FALSE
