/turf/space/transit
	var/spritedirection // push things that get caught in the transit tile (opposite) this direction
	var/throws = TRUE
	var/forbids_building = TRUE
	plane = TURF_PLANE

/turf/space/transit/New()
	if(loc)
		var/area/A = loc
		A.area_turfs += src

	update_icon()

/turf/space/transit/initialize()
	return

/turf/space/transit/update_icon()
	icon_state = ""

	var/dira=""
	var/i=0
	switch(spritedirection)
		if(SOUTH) // North to south
			dira="ns"
			i=1+(abs((x^2)-y)%15) // Vary widely across X, but just decrement across Y

		if(NORTH) // South to north  I HAVE NO IDEA HOW THIS WORKS I'M SORRY.  -Probe
			dira="ns"
			i=1+(abs((x^2)-y)%15) // Vary widely across X, but just decrement across Y

		if(WEST) // East to west
			dira="ew"
			i=1+(((y^2)+x)%15) // Vary widely across Y, but just increment across X

		if(EAST) // West to east
			dira="ew"
			i=1+(((y^2)-x)%15) // Vary widely across Y, but just increment across X

		/*
		if(NORTH) // South to north (SPRITES DO NOT EXIST!)
			dira="sn"
			i=1+(((x^2)+y)%15) // Vary widely across X, but just increment across Y

		if(EAST) // West to east (SPRITES DO NOT EXIST!)
			dira="we"
			i=1+(abs((y^2)-x)%15) // Vary widely across X, but just increment across Y
		*/

		else
			icon_state="black"
	if(icon_state != "black")
		icon_state = "speedspace_[dira]_[i]"

/turf/space/transit/ChangeTurf(var/turf/N, var/tell_universe=1, var/force_lighting_update = 0, var/allow = 0)
	return ..(N, tell_universe, 1, allow)

//Overwrite because we dont want people building rods in space.
/turf/space/transit/attackby(obj/O as obj, mob/user as mob)
	return forbids_building ? 0 : ..()

/turf/space/transit/canBuildCatwalk()
	return forbids_building ? BUILD_FAILURE : ..()

/turf/space/transit/canBuildLattice()
	return forbids_building ? BUILD_FAILURE : ..()

/turf/space/transit/canBuildPlating()
	return forbids_building ? BUILD_SILENT_FAILURE : ..()

/turf/space/transit/Entered(atom/movable/A, atom/OL)
	..()
	if(!throws || !istype(A) || isobserver(A) || istype(A, /obj/effect/beam) || istype(A, /obj/structure/shuttle))
		return
	if(!A.locked_to && !A.throwing)
		if(!is_blocked_turf(get_step(src, spritedirection)))
			A.throw_at(get_edge_target_turf(src, spritedirection), 3, 3)
		else
			var/ccw = counterclockwise_perpendicular_dirs[spritedirection]
			var/cw = clockwise_perpendicular_dirs(spritedirection)
			var/list/dirstocheck = list(ccw = 0,cw = 0)
			var/turf/space/transit/check
			var/turf/space/transit/sideturfnearus
			for(var/direction in dirstocheck)
				for(check = get_step(src, spritedirection); !check || check.type == /turf/space || !is_blocked_turf(check); check = get_step(check,direction))
					if(istype(check) && check.spritedirection != src.spritedirection)
						break
					sideturfnearus = get_step(check,opposite_dirs[spritedirection])
					if(!istype(sideturfnearus) || sideturfnearus.spritedirection != src.spritedirection || is_blocked_turf(sideturfnearus))
						if(is_blocked_turf(sideturfnearus))
							dirstocheck[direction] = 0
						break
					dirstocheck[direction]++
			if(dirstocheck[dirstocheck[1]] || dirstocheck[dirstocheck[2]])
				var/tostep
				if(dirstocheck[dirstocheck[1]] > dirstocheck[dirstocheck[2]])
					tostep = cw
				else if(dirstocheck[dirstocheck[1]] < dirstocheck[dirstocheck[2]])
					tostep = ccw
				else
					tostep = pick(dirstocheck)
				sleep(1)
				if(A in src)
					step(A,tostep)

/turf/space/transit/north // moving to the north

	spritedirection = SOUTH  // south because the space tile is scrolling south
	icon_state="debug-north"

/turf/space/transit/south // moving to the south

	spritedirection = NORTH
	icon_state="debug-south"

/turf/space/transit/east // moving to the east

	spritedirection = WEST
	icon_state="debug-east"

/turf/space/transit/west // moving to the west

	spritedirection = EAST
	icon_state="debug-west"

/turf/space/transit/horizon //special transit turf for Horizon

	spritedirection = SOUTH //the ship is moving forward
	forbids_building = FALSE
	plane = ABOVE_PARALLAX_PLANE
	icon_state="debug-north"

/turf/space/transit/faketransit //special transit turf for Horizon that doesn't throw you around like a little bitch

	spritedirection = SOUTH //the ship is moving forward
	throws = FALSE
	forbids_building = FALSE
	plane = ABOVE_PARALLAX_PLANE
	icon_state="debug-north"
