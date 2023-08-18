
//For spells designed to be inherent abilities given to mobs via their species datum

/spell/targeted/genetic/invert_eyes
	name = "Invert eyesight"
	desc = "Inverts the colour spectrum you see, letting you see clearly in the dark, but not in the light."
	panel = "Mutant Powers"
	user_type = USER_TYPE_GENETIC
	range = SELFCAST

	charge_type = Sp_RECHARGE

	spell_flags = INCLUDEUSER

	invocation_type = SpI_NONE

	override_base = "genetic"
	hud_state = "wiz_sleepold"

/spell/targeted/genetic/invert_eyes/cast(list/targets, mob/user)
	for(var/mob/living/carbon/human/M in targets)
		var/datum/organ/internal/eyes/mushroom/E = M.internal_organs_by_name["eyes"]
		if(istype(E))
			E.dark_mode = !E.dark_mode

/spell/regen_limbs	//Slime people
	name = "Regenerate Limbs"
	abbreviation = "RL"
	desc = "Sprout new limbs to replace lost ones."
	panel = "Racial Abilities"
	override_base = "racial"
	hud_state = "racial_regen_limbs"
	spell_flags = INCLUDEUSER
	charge_type = Sp_RECHARGE
	charge_max = 100
	range = SELFCAST
	cast_sound = 'sound/effects/squelch1.ogg'
	still_recharging_msg = "<span class='notice'>You're still regaining your strength.</span>"

/spell/regen_limbs/cast(list/targets, mob/user)
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/list/priority_organs = list()
		if(H.get_organ(LIMB_GROIN))
			priority_organs.Add(H.get_organ(LIMB_GROIN))
		if(H.get_organ(LIMB_RIGHT_LEG))
			priority_organs.Add(H.get_organ(LIMB_RIGHT_LEG))
		if(H.get_organ(LIMB_LEFT_LEG))
			priority_organs.Add(H.get_organ(LIMB_LEFT_LEG))
		if(H.get_organ(LIMB_RIGHT_FOOT))
			priority_organs.Add(H.get_organ(LIMB_RIGHT_FOOT))
		if(H.get_organ(LIMB_LEFT_FOOT))
			priority_organs.Add(H.get_organ(LIMB_LEFT_FOOT))
		for(var/organ_name in H.organs_by_name)
			if(!(H.organs_by_name[organ_name] in priority_organs))
				priority_organs.Add(H.organs_by_name[organ_name])

		var/has_regenerated = FALSE
		for(var/datum/organ/external/O in priority_organs)
			if(O.status & ORGAN_DESTROYED)
				if(O.name == LIMB_LEFT_FOOT || O.name == LIMB_RIGHT_FOOT || O.name == LIMB_LEFT_HAND || O.name == LIMB_RIGHT_HAND)
					if(!(O.parent.status & ORGAN_DESTROYED))
						if(H.nutrition >= 50)
							H.nutrition -= 50
							O.rejuvenate_limb()
							has_regenerated = TRUE
							user.visible_message("<span class='warning'>\The [user] sprouts a new [O.display_name]!</span>",\
 								"<span class='notice'>You sprout a new [O.display_name]!</span>")
				else if(H.nutrition >= 100)
					H.nutrition -= 100
					O.rejuvenate_limb()
					has_regenerated = TRUE
					user.visible_message("<span class='warning'>\The [user] sprouts a new [O.display_name]!</span>",\
						"<span class='notice'>You sprout a new [O.display_name]!</span>")

		H.resting = 0
		H.regenerate_icons()
		H.update_canmove()
		if(!has_regenerated)
			to_chat(user, "<span class='warning'>You don't have enough energy to regenerate!</span>")

/spell/regen_limbs/choose_targets(mob/user = usr)
	var/list/targets = list()
	targets += user
	return targets

/spell/regen_limbs/is_valid_target(atom/target, mob/user, options, bypass_range = 0)
	return(target == user)

/spell/targeted/transfer_reagents
	name = "Fertilize"
	desc = "Taps into your internal nutrient storage to fertilize a plant."
	abbreviation = "TR"

	spell_flags = WAIT_FOR_CLICK
	range = 1
	max_targets = 1

	override_base = "racial"
	hud_state = "transfer_reagents"

	charge_max = 20

	invocation_type = SpI_NONE

/spell/targeted/transfer_reagents/is_valid_target(atom/target, mob/user, options, bypass_range = 0)
	if(!istype(target, /obj/machinery/portable_atmospherics/hydroponics))
		to_chat(holder, "<span class='warning'>That's neither soil nor an hydroponic tray!</span>")
		return FALSE
	return TRUE

/spell/targeted/transfer_reagents/cast(var/list/targets, mob/user)
	..()
	if(!holder.reagents)
		to_chat(holder, "<span class='warning'>Uhh that's not gonna work. You don't seem to have reagents!</span>")
		CRASH("[holder] tried to cast [name] but has no reagents!")

	if(holder.reagents.total_volume <= 5)
		to_chat(holder, "<span class='warning'>You don't have enough reagents in your system!</span>")
		return 1

	for(var/obj/machinery/portable_atmospherics/hydroponics/target in targets)
		to_chat(holder, "You secrete some nutritional sap from your fingertips and let it fall into \the [target].")
		holder.reagents.trans_to(target, 5, log_transfer = TRUE, whodunnit = holder)

/spell/targeted/psionic
	name = "psionic power"
	desc = "Does... something... to another member of your species."
	abbreviation = "GP"

	spell_flags = WAIT_FOR_CLICK
	range =	7
	max_targets = 1

	override_base = "genetic"
	hud_state = "gen_project"

	charge_max = 20

	invocation_type = SpI_NONE

/spell/targeted/psionic/cast_check(skipcharge, mob/user)
	if(!isgrey(user))
		to_chat(holder, "<span class='warning'>You cannot use this power as this species.</span>")
		return FALSE
	return ..()

/spell/targeted/psionic/is_valid_target(atom/target, mob/user, options, bypass_range = 0)
	if(user.isUnconscious() || user.is_wearing_item(/obj/item/clothing/head/tinfoil) || (M_PSY_RESIST in user.mutations))
		to_chat(holder, "<span class='warning'>This specimen is not responsive to your power.</span>")
		return FALSE
	return ..()

/spell/targeted/psionic/cast(var/list/targets, mob/user)
	..()
	if(isliving(user))
		for(var/mob/living/target in targets)
			do_effect(target,user)

/spell/targeted/psionic/proc/do_effect(mob/living/target,mob/living/user)
	return

/spell/targeted/psionic/drain
	name = "psionic drain"
	desc = "Drains health from another member of your species to add to yours."
	abbreviation = "GD"

	hud_state = "gen_project"

	charge_max = 20

/spell/targeted/psionic/drain/is_valid_target(atom/target, mob/user, options, bypass_range = 0)
	if(!isgrey(target))
		to_chat(holder, "<span class='warning'>You cannot use this power on other species.</span>")
		return FALSE
	return ..()

/spell/targeted/psionic/drain/do_effect(mob/living/target,mob/living/user)
	to_chat(user, "<span class='danger'>You drain health from [target] to add to your own.</span>")
	to_chat(target, "<span class='userdanger'>[user] drains some of your health to add to theirs!</span>")
	target.adjustBruteLoss(20)
	target.adjustFireLoss(20)
	target.heal_organ_damage(20,20)

/spell/targeted/psionic/heal
	name = "psionic heal"
	desc = "Heals health from another member of your species to add to yours."
	abbreviation = "GH"

	spell_flags = WAIT_FOR_CLICK | INCLUDEUSER
	hud_state = "gen_project"

	charge_max = 20

/spell/targeted/psionic/heal/is_valid_target(atom/target, mob/user, options, bypass_range = 0)
	if(!isgrey(target))
		to_chat(holder, "<span class='warning'>You cannot use this power on other species.</span>")
		return FALSE
	return ..()

/spell/targeted/psionic/heal/do_effect(mob/living/target,mob/living/user)
	to_chat(target, "<span class='notice'>[user == target ? "You" : "[user]"] mend[user == target ? "" : "s"] your wounds!</span>")
	target.heal_organ_damage(10,10)

/spell/targeted/psionic/brainloss
	name = "psionic headache"
	desc = "Ceases brain functionalities in the affected."
	abbreviation = "GB"

	spell_flags = WAIT_FOR_CLICK
	hud_state = "gen_project"

	charge_max = 20

/spell/targeted/psionic/brainloss/do_effect(mob/living/target,mob/living/user)
	to_chat(target, "<span class='userdanger'>You get a blindingly painful headache.</span>")
	target.adjustBrainLoss(10)
	target.eye_blurry = max(target.eye_blurry, 5)

/spell/targeted/psionic/stun
	name = "psionic stun"
	desc = "Ceases leg motor functionalities in the affected."
	abbreviation = "GS"

	spell_flags = WAIT_FOR_CLICK
	hud_state = "gen_project"

	charge_max = 20

/spell/targeted/psionic/stun/do_effect(mob/living/target,mob/living/user)
	to_chat(target, "<span class='userdanger'>You suddenly lose your sense of balance!</span>")
	target.emote("me", 1, "collapses!")
	target.Knockdown(2)

/spell/targeted/psionic/knockout
	name = "psionic knockout"
	desc = "Causes the affected to lose consciousness."
	abbreviation = "GK"

	spell_flags = WAIT_FOR_CLICK
	hud_state = "gen_project"

	charge_max = 20

/spell/targeted/psionic/knockout/do_effect(mob/living/target,mob/living/user)
	to_chat(target, "<span class='userdanger'>You feel exhausted...</span>")
	target.drowsyness += 4
	spawn(2 SECONDS)
		target.sleeping += 3

/spell/targeted/psionic/hallucinate
	name = "psionic hallucination"
	desc = "Causes the affected to hallucinate."
	abbreviation = "GL"

	spell_flags = WAIT_FOR_CLICK
	hud_state = "gen_project"

	charge_max = 20

/spell/targeted/psionic/hallucinate/do_effect(mob/living/target,mob/living/user)
	to_chat(target, "<span class='userdanger'>Your mind feels less stable, and you feel nervous.</span>")
	target.hallucination += 60 // For some reason it has to be this high at least or seemingly nothing happens
	target.Jitter(20)
	target.stuttering += 20

/spell/targeted/psionic/disarm
	name = "psionic disarm"
	desc = "Ceases arm motor functionalities in the affected."
	abbreviation = "GA"

	spell_flags = WAIT_FOR_CLICK
	hud_state = "gen_project"

	charge_max = 20

/spell/targeted/psionic/disarm/do_effect(mob/living/target,mob/living/user)
	to_chat(target, "<span class='userdanger'>Your arm jerks involuntarily, and you drop what you're holding!</span>")
	target.drop_item()

/spell/targeted/psionic/pacify
	name = "psionic pacification"
	desc = "Ceases arm motor functionalities in the affected."
	abbreviation = "GP"

	spell_flags = WAIT_FOR_CLICK
	hud_state = "gen_project"

	charge_max = 20

/spell/targeted/psionic/pacify/do_effect(mob/living/target,mob/living/user)
	to_chat(target, "<span class='userdanger'>You feel strangely calm and passive. What's the point in fighting?</span>")
	target.reagents.add_reagent(CHILLWAX, 1)
