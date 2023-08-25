//Cannot actually trigger due to the absence a custom can_start() proc and isn't spawned anywhere else, and that's for the better seeing as those diseases are deprecated.
//I'll let someone else take the decision to remove this file altogether.

/datum/event/disease_outbreak
	announceWhen	= 90

/datum/event/disease_outbreak/announce()
	if(..())
		biohazard_alert()

/datum/event/disease_outbreak/setup()
	announceWhen = rand(30, 150) //Thanks Doc

/datum/event/disease_outbreak/start()
	var/virus_type = pick(/datum/disease/dnaspread, /datum/disease/advance/flu, /datum/disease/advance/cold, /datum/disease/brainrot, /datum/disease/magnitis)

	for(var/mob/living/carbon/human/H in shuffle(living_mob_list))
		var/foundAlready = 0	// don't infect someone that already has the virus
		var/turf/T = get_turf(H)
		if(!T)
			continue
		if(T.z != map.zMainStation)
			continue
		for(var/datum/disease/D in H.viruses)
			foundAlready = 1
		if(H.stat == 2 || foundAlready)
			continue

		if(virus_type == /datum/disease/dnaspread)		//Dnaspread needs strain_data set to work.
			if((!H.dna) || (H.sdisabilities & BLIND))	//A blindness disease would be the worst.
				continue
			var/datum/disease/dnaspread/D = new
			D.strain_data["name"] = H.real_name
			D.strain_data["UI"] = H.dna.UI.Copy()
			D.strain_data["SE"] = H.dna.SE.Copy()
			D.carrier = 1
			D.holder = H
			D.affected_mob = H
			H.viruses += D
			break
		else
			var/datum/disease/D = new virus_type
			D.carrier = 1
			D.holder = H
			D.affected_mob = H
			H.viruses += D
			break
