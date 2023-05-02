/datum/unit_test/liquids
	var/turf/centreturf

/datum/unit_test/liquids/New()
	if(SSliquid)
		SSliquid.pause()
	centreturf = locate(101, 100, 1) // Nice place with a good atmosphere
	ASSERT(centreturf)
	centreturf.add_to_liquid(WATER,250)
	ASSERT(centreturf.liquid)
	ASSERT(centreturf.liquid.reagents)
	assert_eq(centreturf.liquid.reagents.total_volume, 250)
	assert_eq(centreturf.liquid.reagents.maximum_volume, 1000)
	ASSERT(centreturf.current_puddle)
	ASSERT(puddles.len)
	ASSERT(centreturf.liquid.liquid_objects.len)

/datum/unit_test/liquids/Destroy()
	for(var/datum/liquid/L in puddles)
		qdel(L)

/datum/unit_test/liquids/process/New()
	..()
	for(var/datum/liquid/L in puddles)
		L.process()
	// TODO: checks here
