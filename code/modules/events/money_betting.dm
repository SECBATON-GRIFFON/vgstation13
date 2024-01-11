/datum/event/money_betting
	startWhen = 2
	announceWhen = 1
	endWhen = 9999
	var/list/mob/living/simple_animal/hostile/team_players = list()
	var/list/obj/structure/cage/cages = list()
	//var/mob/living/carbon/human/dummy/commentator
	var/turf/centreturf
	var/slipinfo = ""
	var/list/totalhealth = list("red" = 0,"blue" = 0)
	var/list/totaldamage = list("red" = 0,"blue" = 0)
	var/list/odds = list()
	var/winningteam = "nobody"

/datum/event/money_betting/can_start()
	for(var/obj/machinery/computer/security/telescreen/entertainment/E in machines)
		if(E.active_camera?.c_tag != "Arena")
			var/list/cameras = E.get_available_cameras()
			if(!("Arena" in cameras))
				continue

			centreturf = get_turf(cameras["Arena"])
			if(centreturf)
				break
	if(!centreturf)
		log_debug("Money bet event could not start, no thunderdome found.")
	return centreturf ? 20 : 0

/datum/event/money_betting/setup()
	for(var/obj/machinery/computer/security/telescreen/entertainment/E in machines)
		if(E.active_camera?.c_tag != "Arena")
			var/list/cameras = E.get_available_cameras()
			if(!("Arena" in cameras))
				continue

			var/obj/machinery/camera/selected_camera = cameras["Arena"]
			E.active_camera = selected_camera

			if(!selected_camera)
				continue

			E.active_camera.camera_twitch()
			E.update_active_camera_screen()
		if(E.active_camera && !centreturf)
			centreturf = get_turf(E.active_camera)
	if(centreturf)
		/*commentator = new(locate(centreturf.x,centreturf.y + 6,centreturf.z))
		commentator.generate_name()
		var/datum/outfit/special/with_id/nt_rep/NT = new
		NT.equip(commentator,TRUE)*/
		var/static/list/blocked = list(
			/mob/living/simple_animal/hostile/retaliate/clown,
			/mob/living/simple_animal/hostile/mushroom,
			/mob/living/simple_animal/hostile/faithless/cult,
			/mob/living/simple_animal/hostile/scarybat/cult,
			/mob/living/simple_animal/hostile/creature/cult,
			/mob/living/simple_animal/hostile/slime,
			) + boss_mobs + blacklisted_mobs//Exclusion list for things you don't want to create.

		var/list/critters = existing_typesof(/mob/living/simple_animal/hostile) - existing_typesof_list(blocked)//List of possible hostile mobs

		for(var/turf/T in spiral_block(centreturf,7))
			if(abs(T.x-centreturf.x) % 2 == 1 && abs(T.y-centreturf.y) % 2 == 1 && abs(T.y-centreturf.y) < 4) // Separate centre row, space cages out
				var/chosen = pick_n_take(critters)
				var/mob/living/simple_animal/hostile/C = new chosen
				C.faction = "tdome"
				if(T.x < centreturf.x)
					C.color = "#ff8080"
					totalhealth["red"] += C.health
					totaldamage["red"] += ((C.melee_damage_upper+C.melee_damage_lower)/2)
				else
					C.color = "#8080ff"
					totalhealth["blue"] += C.health
					totaldamage["blue"] += ((C.melee_damage_upper+C.melee_damage_lower)/2)
				C.forceMove(T)
				team_players += C
				var/obj/structure/cage/autoclose/AC = new(T)
				cages += AC
		slipinfo = "<h1>BETTING ODDS FOR [uppertext(time2text(world.timeofday, "Day"))] NIGHT SLAMDOWN</h1><br><h2>TEAMS</h2><br>"
		odds["red"] = (totalhealth["red"]+totaldamage["red"])/(totalhealth["red"]+totaldamage["red"]+totalhealth["blue"]+totaldamage["blue"])
		slipinfo += "Red team to survive: [1/(odds["red"]*2)]/1<br>"
		odds["blue"] = (totalhealth["blue"]+totaldamage["blue"])/(totalhealth["red"]+totaldamage["red"]+totalhealth["blue"]+totaldamage["blue"])
		slipinfo += "Blue team to survive: [1/(odds["blue"]*2)]/1<br><h2>PLAYERS</h2><br>"
		for(var/mob/living/simple_animal/hostile/H in team_players)
			var/team2oppose = H.color == "#ff8080" ? "blue" : "red"
			odds["[H.name]"] = (H.health+((H.melee_damage_upper+H.melee_damage_lower)/2))/(totalhealth[team2oppose]+totaldamage[team2oppose])
			slipinfo += "[H.name] to survive: [1/(odds["[H.name]"]*2)]/1<br>"

		slipinfo += "Please write name(s) of bet to win in new line(s) below to count as valid.<br>"
		for(var/obj/machinery/vending/lotto/V in machines)
			V.build_inventory(list(/obj/item/weapon/paper/betting_slip = 20))

	startWhen = rand(5,10) * 60
	endWhen = startWhen + 200

/datum/event/money_betting/start()
	for(var/obj/structure/cage/C in cages)
		C.toggle_door()
	for(var/mob/living/simple_animal/hostile/H in team_players)
		H.faction = H.color == "#ff8080" ? "tdomered" : "tdomeblue"
	for(var/obj/machinery/vending/lotto/L in machines)
		for(var/datum/data/vending_product/R in L.product_records)
			if(R.product_path == /obj/item/weapon/paper/betting_slip) // all bets are off!
				L.product_records.Remove(R)
	sleep(2 SECONDS)
	for(var/obj/structure/cage/C in cages)
		qdel(C)

/datum/event/money_betting/tick()
	var/redalive = FALSE
	var/bluealive = FALSE
	for(var/mob/living/simple_animal/hostile/H in team_players)
		if(!H.isDead())
			if(H.color == "#ff8080")
				redalive = TRUE
			else if(H.color == "#8080ff")
				bluealive = TRUE
			break
	if(!redalive || !bluealive)
		if(!redalive)
			winningteam = "blue"
		else if(!bluealive)
			winningteam = "red"
		end()

/datum/event/money_betting/end()
	var/redalive = 0
	var/bluealive = 0
	for(var/mob/living/simple_animal/hostile/H in team_players)
		if(!H.isDead())
			if(H.color == "#ff8080")
				redalive++
			else if(H.color == "#8080ff")
				bluealive++
	winningteam = redalive > bluealive ? "red" : bluealive > redalive ? "blue" : "nobody"
	var/datum/command_alert/bet_announce/BA = new
	BA.alert_title = "Central Command [time2text(world.timeofday, "Day")] Night Slamdown"
	BA.message = "A thunderdome fight has concluded, with the winning team being [winningteam]. Be sure to collect any winnings."
	command_alert(BA)
	sleep(10 SECONDS)
	for(var/mob/living/simple_animal/hostile/H in team_players)
		qdel(H)

/datum/event/money_betting/announce()
	var/datum/command_alert/bet_announce/BA = new
	BA.alert_title = "Central Command [time2text(world.timeofday, "Day")] Night Slamdown"
	BA.message = "A thunderdome fight is scheduled to happen within the next [startWhen / 60] minutes. The station's lottery machines now have an exclusive type of betting slip available for purchase. All nearby entertainment monitors will be broadcasting the fight!"
	command_alert(BA)
