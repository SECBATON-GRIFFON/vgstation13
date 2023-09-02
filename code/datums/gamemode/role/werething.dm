/datum/role/werething
	name = "werething"
	var/mob/host

/datum/role/werething/OnPostSetup(laterole)
	if(istype(antag.current,/mob/camera/werething))
		var/mob/camera/werething/WT = antag.current
		host = WT.attached_mob
		return TRUE
	return FALSE

/datum/role/werething/Greet(var/greeting,var/custom)
	if(!greeting)
		return

	var/icon/logo = icon('icons/logos.dmi', logo_state)
	switch(greeting)
		if (GREET_CUSTOM)
			to_chat(antag.current, "<img src='data:image/png;base64,[icon2base64(logo)]' style='position: relative; top: 10;'/> <span class='danger'>[custom]</span>")
		else
			var/thingname = "Thing"
			if(istype(antag.current,/mob/camera/werething))
				var/mob/camera/werething/WT = antag.current
				if(ispath(WT.transform_type,/datum/species))
					var/datum/species/D = WT.transform_type
					thingname = initial(D.name)
			to_chat(antag.current, "<img src='data:image/png;base64,[icon2base64(logo)]' style='position: relative; top: 10;'/>\
			<span class='danger'>You are a Were-[thingname] in [host]'s body!<br>\
			To activate \his alter-ego, select the \"transform\" option on the top right!<br>\
			It will last about 5 minutes, from that they will change back to their original form and you will be unable to use this ability for an additional 5 minutes.</span>")

	to_chat(antag.current, "<span class='info'><a HREF='?src=\ref[antag.current];getwiki=[wikiroute]'>(Wiki Guide)</a></span>")

/datum/role/werething/process()
	. = ..()
	if(!host && istype(antag.current,/mob/camera/werething))
		to_chat(antag.current,"<span class='sinister'>Your host no longer exists, so you have been released from them...</span>")
		qdel(antag.current)
	else if(!antag.current && !isliving(host))
		to_chat(host,"<span class='sinister'>Your were-form no longer exists, so you have been released from them...</span>")
		qdel(host)

/datum/role/werething/ForgeObjectives()
	if(antag.current.client.prefs.antag_objectives && living_mob_list.len)
		for(var/i in 1 to min(3,living_mob_list.len))
			if(prob(67))
				AppendObjective(/datum/objective/target/assassinate)
			else
				AppendObjective(/datum/objective/target/harm)
	else
		AppendObjective(/datum/objective/freeform/werething)

/datum/objective/freeform/werething
	explanation_text = "Cause havoc in your host form's alter ego."

/mob/camera/werething
	var/mob/living/carbon/human/attached_mob
	var/datum/action/werething/werething_transform_button
	var/transform_type = /datum/species/tajaran
	var/old_species_type

/mob/camera/werething/New(loc, mob/living/carbon/human/attach_mob, ishost = FALSE)
	. = ..()
	if(ispath(transform_type,/datum/species))
		var/datum/species/D = transform_type
		name = "Were-[initial(D.name)]"
	if(attach_mob)
		attached_mob = attach_mob
		if(loc != attach_mob)
			forceMove(attach_mob)
		if(!ishost)
			werething_transform_button = new()
			werething_transform_button.Grant(src)

/mob/camera/werething/proc/activate()
	attached_mob.visible_message("<span class='danger'>[attached_mob] has shifted and contorted into becoming a were-thing!</span>","<span class='sinister'>You have been taken over by your were-thing form! Now, all you can do is watch as its carnage unfolds...</span>")
	var/mob/dummy = new(attached_mob.loc)
	attached_mob.mind.transfer_to(dummy)
	src.mind.transfer_to(attached_mob)
	dummy.mind.transfer_to(src)
	qdel(dummy)
	old_species_type = src.attached_mob.species.name
	if(ispath(transform_type,/datum/species))
		var/datum/species/S = transform_type
		if(initial(S.name) == "Human")
			// TODO: random appearance
		else
			attached_mob.set_species(initial(S.name))
	else if(ispath(transform_type,/mob/living))
		attached_mob.transmogrify(transform_type)
	var/datum/role/werething/WR =  attached_mob.mind.GetRole(WERETHING)
	if(WR)
		WR.host = src

/mob/camera/werething/proc/deactivate()
	attached_mob = attached_mob.completely_untransmogrify()
	attached_mob.set_species(old_species_type)
	var/mob/dummy = new(attached_mob.loc)
	attached_mob.mind.transfer_to(dummy)
	src.mind.transfer_to(attached_mob)
	dummy.mind.transfer_to(src)
	qdel(dummy)
	attached_mob.visible_message("<span class='notice'>[attached_mob] has shifted and contorted back into their original form.</span>","<span class='sinister'>You have returned to your original form. Hopefully not too much damage happened while you were out...</span>")
	var/datum/role/werething/WR =  attached_mob.mind.GetRole(WERETHING)
	if(WR)
		WR.host = attached_mob

/*/mob/camera/werething/Stat()
	if(werething_transform_button && statpanel("Status"))
		stat(null, "Time left as [name]: [werething_transform_button.time_since_last_done]")

	..()*/

/datum/action/werething
	name = "Take over host!"
	desc = "Activate the host's were-form."
	var/time_since_last_done

/datum/action/werething/Trigger()
	if(world.time - time_since_last_done < 10 MINUTES)
		to_chat(owner,"<span class='warning'>This is not ready yet! Wait [(world.time - time_since_last_done)/10] seconds!")
	if(istype(owner,/mob/camera/werething))
		var/mob/camera/werething/ownerWT = owner
		time_since_last_done = world.time
		ownerWT.activate()
		Remove(owner)
		spawn(5 MINUTES)
			if(ownerWT)
				ownerWT.deactivate()
				Grant(owner)
