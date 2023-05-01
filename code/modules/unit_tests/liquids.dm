/datum/unit_test/liquids
	var/datum/liquid/liquid
	var/turf/centreturf

/datum/unit_test/liquids/New()
	..()
	centreturf = locate(3,3,1)
	ASSERT(centreturf)
	liquid = new(centreturf)
	ASSERT(liquid.reagents)
	assert_eq(liquid.reagents.total_volume, 1000)
	assert_eq(centreturf.liquid, liquid)
	ASSERT(centreturf.current_puddle)
	ASSERT(puddles.len)
	ASSERT(liquid.liquid_objects.len)

/datum/unit_test/liquids/Destroy()
	qdel(liquid)
	ASSERT(!puddles.len)
	ASSERT(!centreturf.liquid)
	..()
