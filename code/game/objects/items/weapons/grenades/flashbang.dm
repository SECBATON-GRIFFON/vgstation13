/obj/item/weapon/grenade/flashbang
	name = "flashbang"
	icon_state = "flashbang"
	item_state = "flashbang"
	origin_tech = Tc_MATERIALS + "=2;" + Tc_COMBAT + "=1"
	var/banglet = 0

/obj/item/weapon/grenade/flashbang/prime(banglet)
	flashbangprime(delsrc = TRUE, isbanglet = banglet)

/atom/proc/flashbangprime(var/delsrc = FALSE, var/ignore_protection = FALSE, isbanglet = FALSE, range = world.view, blobdmg = TRUE)
	var/turf/flashbang_turf = get_turf(src)
	if(!flashbang_turf)
		return

	var/list/mobs_to_flash_and_bang = get_all_mobs_in_dview(flashbang_turf, range, list(/mob/living/carbon/brain, /mob/living/silicon/ai))

	var/mob/living/holder = get_holder_of_type(src, /mob/living)
	if(holder) //Holding a flashbang while it goes off is a bad idea.
		flashbang(flashbang_turf, holder, TRUE)
		mobs_to_flash_and_bang -= holder
		if(ismob(loc))
			var/mob/M = loc
			M.drop_from_inventory(src)

	for(var/mob/living/M in mobs_to_flash_and_bang)
		if(M.isVentCrawling()) //possibly more exceptions to be added in the future
			continue
		flashbang(flashbang_turf, M, ignore_protection, isbanglet)

	if(blobdmg)
		for(var/obj/effect/blob/B in get_hear(8,flashbang_turf))     		//Blob damage here
			var/damage = round(15/(get_dist(B,get_turf(src))+1))
			B.health -= damage
			B.update_health()
			B.update_icon()
	if(delsrc)
		qdel(src)

/atom/proc/flashbang(var/turf/T, var/mob/living/M, var/ignore_protection = 0, var/isbanglet = FALSE)
	if (locate(/obj/item/weapon/cloaking_device, M))			// Called during the loop that bangs people in lockers/containers and when banging
		for(var/obj/item/weapon/cloaking_device/S in M)			// people in normal view.  Could theroetically be called during other explosions.
			S.active = 0										// -- Polymorph
			S.icon_state = "shield0"

//Checking for protections
	var/eye_safety = 0
	var/ear_safety = 0

	if(!ignore_protection && loc != M.loc)
		eye_safety = M.eyecheck()
		ear_safety = M.earprot() //some arbitrary measurement of ear protection, I guess? doesn't even matter if it goes above 1

		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			var/obj/item/headwear = H.head
			if (headwear?.NoiseDampening())
				ear_safety += 1
		if(M_HULK in M.mutations)
			ear_safety += 1
		if(istype(M.loc, /obj/mecha))
			ear_safety += 1

//Flashing everyone
	var/mob/living/silicon/robot/R = null //Yes. I KNOW.
	if(isrobot(M))
		R = M
	if(eye_safety < 1 && !M.blinded)
		M.flash_eyes(visual = 1, affect_silicon = 1)
		if(get_dist(M, T) <= 3)
			var/strength = 8
			if(R && (HAS_MODULE_QUIRK(R, MODULE_HAS_FLASH_RES)))
				strength = strength/2
			if(R && (HAS_MODULE_QUIRK(R, MODULE_IS_FLASHPROOF)))
				strength = null
			if(strength)
				M.Stun(strength)
				M.Knockdown(strength)
		else
			if(issilicon(M))
				var/salt = 4//The amount of salt we're going to generate.
				if(R && (HAS_MODULE_QUIRK(R, MODULE_IS_FLASHPROOF)))
					salt = salt/2 //Half as much.
				if(R && (HAS_MODULE_QUIRK(R, MODULE_IS_FLASHPROOF)))
					salt = null //No salt.
				if(salt)
					M.Stun(salt)
					M.Knockdown(salt)
			else if (get_dist(M, T) <= 5)
				M.Knockdown(2)
				M.Stun(2)
			else
				M.Knockdown(1)
				M.Stun(1)

//Now applying sound
	if(!M.is_deaf())
		if(!ear_safety)
			to_chat(M, "<span class='userdanger'>BANG</span>")
			playsound(src, 'sound/effects/bang.ogg', 60, 1)
		else
			to_chat(M, "<span class='danger'>BANG</span>")
			playsound(src, 'sound/effects/bang.ogg', 25, 1)

	if((get_dist(M, T) <= 2 || src.loc == M.loc || src.loc == M))
		if(ear_safety > 0)
			if(!M.is_deaf())
				M.Stun(2)
				M.Knockdown(2)
		else
			if(!M.is_deaf())
				M.Stun(8)
				M.Knockdown(8)
			if ((prob(14) || (M == src.loc && prob(70))))
				M.ear_damage += rand(1, 10)
			else
				M.ear_damage += rand(0, 5)
				M.ear_deaf = max(M.ear_deaf,15)

	else if(get_dist(M, T) <= 3)
		if(!ear_safety)
			if(!M.is_deaf())
				M.Stun(6)
				M.Knockdown(6)
			M.ear_damage += rand(0, 3)
			M.ear_deaf = max(M.ear_deaf,10)

	else if(get_dist(M, T) <= 5)
		if(!ear_safety)
			if(!M.is_deaf())
				M.Stun(4)
				M.Knockdown(4)
			M.ear_damage += rand(0, 3)
			M.ear_deaf = max(M.ear_deaf,10)

	else if(!ear_safety)
		if(!M.is_deaf())
			if (issilicon(M))
				M.Stun(4)
			M.Knockdown(1)
		M.ear_damage += rand(0, 1)
		M.ear_deaf = max(M.ear_deaf,5)

//This really should be in mob not every check
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/datum/organ/internal/eyes/E = H.internal_organs_by_name["eyes"]
		if (E && E.damage >= E.min_bruised_damage)
			to_chat(M, "<span class='warning'>Your eyes start to burn badly!</span>")
			if(!isbanglet && !(istype(src , /obj/item/weapon/grenade/flashbang/clusterbang)))
				if (E.damage >= E.min_broken_damage)
					to_chat(M, "<span class='warning'>You can't see anything!</span>")
	if (M.ear_damage >= 15)
		to_chat(M, "<span class='warning'>Your ears start to ring badly!</span>")
		if(!isbanglet && !(istype(src , /obj/item/weapon/grenade/flashbang/clusterbang)))
			if (prob(M.ear_damage - 10 + 5))
				to_chat(M, "<span class='warning'>You can't hear anything!</span>")
				M.sdisabilities |= DEAF
	else
		if (M.ear_damage >= 5)
			to_chat(M, "<span class='warning'>Your ears start to ring!</span>")
	M.update_icons()

/obj/item/folding_chair/riotincite
	name = "riot inciting chair"
	desc = "Guaranteed brief chaos when thrown into a crowd."
	var/uses = 1
	var/cooldown = 0 //in seconds
	var/riotlength = 60 //in seconds
	var/timeused = 0
	var/popcorned = 0
	var/riotrange = 4

/obj/item/folding_chair/riotincite/reusable
	uses = 5
	cooldown = 300

/obj/item/folding_chair/riotincite/reusable/infinite
	uses = INFINITY

/obj/item/folding_chair/riotincite/admin // for testing the item
	name = "riot inquisiting chair"
	desc = "Guaranteed brief scrimmage on every throw in!"
	uses = INFINITY
	riotlength = 1

/obj/item/folding_chair/riotincite/longer
	desc = "Guaranteed slightly lengthier chaos when thrown into a crowd."
	riotlength = 300

/obj/item/folding_chair/riotincite/infinite // gunk edition
	desc = "Permanent chaos when thrown into a crowd."
	uses = INFINITY
	riotrange = 7
	riotlength = 0

/obj/item/folding_chair/riotincite/attack_self(mob/user)
	. = ..()
	if(!popcorned)
		new /obj/item/weapon/reagent_containers/food/snacks/popcorn(get_turf(src)) // sit back and watch the chaos unfold!
		popcorned = TRUE

/obj/item/folding_chair/riotincite/throw_impact(atom/hit_atom)
	if(!..() && uses && world.time - timeused >= cooldown)
		uses--
		flashbangprime(ignore_protection = TRUE, range = riotrange, blobdmg = FALSE) // this thing should not hurt the blob, even if that'd be pretty funny
		timeused = world.time

/obj/item/folding_chair/riotincite/flashbang(var/turf/T, var/mob/living/M, var/ignore_protection = 0, var/isbanglet = FALSE)
	if(iscarbon(M) && M.mind)
		if(prob(min(riotlength,300)/3)) // security are immune...sometimes (if the riot is over 5 minutes long it's absolute resistance)
			for(var/obj/item/weapon/implant/I in M)
				if(istype(I, /obj/item/weapon/implant/loyalty))
					if(I.imp_in == M)
						M.visible_message("<span class='userdanger'>[M] stands firm but wearily in front of the thrown chair.</span>", "<span class='danger'>You feel a strange sensation in your head that quickly dissipates.</span>")
						return
		var/datum/faction/F = find_active_faction_by_typeandmember(/datum/faction/syndicate/rioter, null, M.mind)
		if(!F)
			var/success
			F = find_active_faction_by_type(/datum/faction/syndicate/rioter, null, M.mind)
			if(!F)
				F = ticker.mode.CreateFaction(/datum/faction/syndicate/rioter, 0, 1)
				success = F.HandleNewMind(M.mind)
			else
				success = F.HandleRecruitedMind(M.mind)
			if(success)
				var/datum/role/rioter/R = M.mind.GetRole(RIOTER)
				if(R)
					M.visible_message("<span class='userdanger'>[M] briefly convulses!</span>","<span class='big danger'>The chair has activated something in your mind, a deep <i>seated</i> feeling of rebellion!</span>")
					if(prob(20))
						M.say(pick("Oh my god, a chair!","I'm mad!"))
					R.Greet(M)
					R.ForgeObjectives()
					R.AnnounceObjectives()
					update_faction_icons()
					if(riotlength)
						spawn((riotlength+(prob(10)*(riotlength/10))) SECONDS) // 10% chance for a rioter to riot about 10% longer than everyone else, for a little but of funny
							if(R)
								F.HandleRemovedRole(R)
								R.Drop(0)
								update_faction_icons()

/obj/effect/smoke/flashbang
	name = "illumination"
	time_to_live = 10
	opacity = 0
	icon_state = "sparks"

/obj/effect/smoke/flashbang/New()
	..()
	set_light(15)

/obj/item/weapon/grenade/flashbang/clusterbang//Created by Polymorph, fixed by Sieve
	desc = "Use of this weapon may constiute a war crime in your area, consult your local captain."
	name = "clusterbang"
	icon = 'icons/obj/grenade.dmi'
	icon_state = "clusterbang"

/obj/item/weapon/grenade/flashbang/clusterbang/prime()
	var/numspawned = rand(4,8)
	var/again = 0
	for(var/more = numspawned,more > 0,more--)
		if(prob(35))
			again++
			numspawned --

	for(,numspawned > 0, numspawned--)
		spawn(0)
			new /obj/item/weapon/grenade/flashbang/cluster(src.loc)//Launches flashbangs
			playsound(src, 'sound/weapons/armbomb.ogg', 75, 1, -3)

	for(,again > 0, again--)
		spawn(0)
			new /obj/item/weapon/grenade/flashbang/clusterbang/segment(src.loc)//Creates a 'segment' that launches a few more flashbangs
			playsound(src, 'sound/weapons/armbomb.ogg', 75, 1, -3)
	spawn(0)
		qdel(src)
		return

/obj/item/weapon/grenade/flashbang/clusterbang/segment
	desc = "A smaller segment of a clusterbang. Better run."
	name = "clusterbang segment"
	icon = 'icons/obj/grenade.dmi'
	icon_state = "clusterbang_segment"

/obj/item/weapon/grenade/flashbang/clusterbang/segment/New()//Segments should never exist except part of the clusterbang, since these immediately 'do their thing' and asplode
	icon_state = "clusterbang_segment_active"
	active = 1
	banglet = 1
	var/stepdist = rand(1,4)//How far to step
	var/temploc = src.loc//Saves the current location to know where to step away from
	walk_away(src,temploc,stepdist)//I must go, my people need me
	var/dettime = rand(15,60)
	spawn(dettime)
		prime()
	..()

/obj/item/weapon/grenade/flashbang/clusterbang/segment/prime()
	var/numspawned = rand(4,8)
	for(var/more = numspawned,more > 0,more--)
		if(prob(35))
			numspawned --

	for(,numspawned > 0, numspawned--)
		spawn(0)
			new /obj/item/weapon/grenade/flashbang/cluster(src.loc)
			playsound(src, 'sound/weapons/armbomb.ogg', 75, 1, -3)
	spawn(0)
		qdel(src)
		return

/obj/item/weapon/grenade/flashbang/cluster/New()//Same concept as the segments, so that all of the parts don't become reliant on the clusterbang
	spawn(0)
		icon_state = "flashbang_active"
		active = 1
		banglet = 1
		var/stepdist = rand(1,3)
		var/temploc = src.loc
		walk_away(src,temploc,stepdist)
		var/dettime = rand(15,60)
		spawn(dettime)
		prime()
	..()
