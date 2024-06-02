/datum/artifact_effect/reagentblock
	effecttype = "reagentblock"
	valid_style_types = list(ARTIFACT_STYLE_ANOMALY, ARTIFACT_STYLE_RELIQUARY)
	effect = list(ARTIFACT_EFFECT_TOUCH, ARTIFACT_EFFECT_AURA, ARTIFACT_EFFECT_PULSE)
	var/duration = 0
	var/reagent_added = STASIZINE
	copy_for_battery = list("duration")

/datum/artifact_effect/reagentblock/New()
	..()
	effect_type = pick(5,7)
	duration = rand(600,6000)
	reagent_added = pick(STASIZINE,ANTISTASIZINE)
	if(effect == ARTIFACT_EFFECT_AURA)
		effectrange = rand(1,5)

/datum/artifact_effect/reagentblock/DoEffectTouch(var/mob/living/user)
	if(iscarbon(user))
		add_stasizine(user)

/datum/artifact_effect/reagentblock/DoEffectAura()
	if(holder)
		for(var/mob/living/carbon/C in range(effectrange,get_turf(holder)))
			add_stasizine(C)

/datum/artifact_effect/reagentblock/DoEffectPulse()
	if(holder)
		for(var/mob/living/carbon/C in range(effectrange,get_turf(holder)))
			add_stasizine(C)

/datum/artifact_effect/reagentblock/proc/add_stasizine(var/mob/living/carbon/C)
	var/weakness = GetAnomalySusceptibility(C)
	if(prob(weakness * 100))
		if(C.reagents.has_reagent(reagent_added))
			var/datum/reagent/existingblock = C.reagents.get_reagent(reagent_added)
			existingblock.data = world.time+duration
		else
			C.reagents.add_reagent(reagent_added,30,world.time+duration)