/datum/unit_test/map_specific/pipes/start()
	for(var/obj/machinery/atmospherics/pipe/simple/P in atmos_machines)
		if(!P.node1 || !P.node2)
			fail("Pipe [P] at [P.x],[P.y],[P.z] is missing nodes")

	for(var/obj/machinery/atmospherics/pipe/manifold/P in atmos_machines)
		if(!P.node1 || !P.node2 || !P.node3)
			fail("Pipe [P] at [P.x],[P.y],[P.z] is missing nodes")

	for(var/obj/machinery/atmospherics/pipe/manifold4w/P in atmos_machines)
		if(!P.node1 || !P.node2 || !P.node3 || !P.node4)
			fail("Pipe [P] at [P.x],[P.y],[P.z] is missing nodes")
