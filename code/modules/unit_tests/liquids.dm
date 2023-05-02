/datum/unit_test/liquids
	var/turf/centreturf

/datum/unit_test/liquids/New()
	centreturf = locate(101, 100, 1) // Nice place with a good atmosphere
	ASSERT(centreturf)
	centreturf.add_to_liquid(WATER,250)
	ASSERT(centreturf.liquid)
	ASSERT(centreturf.liquid.reagents)
	assert_eq(centreturf.liquid.reagents.total_volume, 250)
	ASSERT(centreturf.current_puddle)
	ASSERT(puddles.len)
	ASSERT(centreturf.liquid.liquid_objects.len)

/datum/unit_test/liquids/Destroy()
	for(var/obj/O in puddles)
		qdel(O)
