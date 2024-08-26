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
	return

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
		var/turf/check = get_step(src, spritedirection)
		if(check.Cross(null,check) && check.Cross(A))
			A.throw_at(get_edge_target_turf(src, spritedirection), 3, 3)
		else // possible behavior for being on the side, uncomment if you can get this working better
			var/list/dirstocheck = list(counterclockwise_perpendicular_dirs[spritedirection] = 0,clockwise_perpendicular_dirs(spritedirection) = 0)
			var/turf/sideturfnearus
			for(var/direction in dirstocheck)
				for(check = get_step(src, spritedirection); !check.Cross(null,check) && !check.Cross(A); check = get_step(check,direction))
					sideturfnearus = get_step(check,opposite_dirs[spritedirection])
					if(!sideturfnearus.Cross(A) || !sideturfnearus.Cross(null,check))
						dirstocheck[direction] = 0
						break
					dirstocheck[direction]++
			if(dirstocheck[counterclockwise_perpendicular_dirs[spritedirection]] || dirstocheck[clockwise_perpendicular_dirs(spritedirection)])
				var/tostep
				if(dirstocheck[counterclockwise_perpendicular_dirs[spritedirection]] > dirstocheck[clockwise_perpendicular_dirs(spritedirection)])
					tostep = clockwise_perpendicular_dirs(spritedirection)
				else if(dirstocheck[counterclockwise_perpendicular_dirs[spritedirection]] < dirstocheck[clockwise_perpendicular_dirs(spritedirection)])
					tostep = counterclockwise_perpendicular_dirs[spritedirection]
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
