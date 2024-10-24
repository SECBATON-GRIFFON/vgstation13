/datum/pipeline
	var/datum/gas_mixture/air

	var/list/obj/machinery/atmospherics/pipe/members = list()
	var/list/obj/machinery/atmospherics/pipe/edges = list() //Used for building networks

	var/datum/pipe_network/network

	var/alert_pressure = 0
	var/last_pressure_check=0

	var/const/PRESSURE_CHECK_DELAY=5 // 5s delay between pchecks to give pipenets time to recover.

/datum/pipeline/Destroy()
	if(network) //For the pipenet rebuild
		QDEL_NULL(network)
	if(air) //For the pipeline rebuild next tick
		if(air.total_moles)
			temporarily_store_air()
		QDEL_NULL(air)
	//Null the fuck out of all these references
	for(var/obj/machinery/atmospherics/pipe/M in members) //Edges are a subset of members
		M.parent = null
	members = null
	edges = null
	..()

/datum/pipeline/proc/process()//This use to be called called from the pipe networks
	if((world.timeofday - last_pressure_check) / 10 >= PRESSURE_CHECK_DELAY)
		//Check to see if pressure is within acceptable limits
		var/pressure = air.pressure
		if(pressure > alert_pressure)
			for(var/obj/machinery/atmospherics/pipe/member in members)
				if(!member.check_pressure(pressure))
					// Delay next update so we have a chance to recalculate.
					last_pressure_check=world.timeofday
					break //Only delete 1 pipe per process


	//Allow for reactions
	//air.react() //Should be handled by pipe_network now

/datum/pipeline/proc/temporarily_store_air()
	//Update individual gas_mixtures by volume ratio

	for(var/obj/machinery/atmospherics/pipe/member in members)
		member.air_temporary = new()
		member.air_temporary.volume = member.volume
		member.air_temporary.copy_from(air)

/datum/pipeline/proc/build_pipeline(obj/machinery/atmospherics/pipe/base)
	var/list/possible_expansions = list(base)
	members = list(base)
	edges = list()

	var/volume = base.volume
	base.parent = src
	alert_pressure = base.alert_pressure

	if(base.air_temporary)
		air = base.air_temporary
		base.air_temporary = null
	else
		air = new

	while(possible_expansions.len>0)
		for(var/obj/machinery/atmospherics/pipe/borderline in possible_expansions)

			var/list/result = borderline.pipeline_expansion()
			var/edge_check = result.len

			if(result.len>0)
				for(var/obj/machinery/atmospherics/pipe/item in result)
					if(item.parent != src)
						if(item.parent)
							//Destroy the old pipeline so that the air is stored in the pipes
							//This could be optimized significantly by making it merge item.parent into this pipeline instead (or vice versa) but I'm just fixing a bug here
							qdel(item.parent)
						members += item
						possible_expansions += item

						volume += item.volume
						item.parent = src

						alert_pressure = min(alert_pressure, item.alert_pressure)

						if(item.air_temporary)
							air.merge(item.air_temporary)

					edge_check--

			if(edge_check>0)
				edges += borderline

			possible_expansions -= borderline

	air.volume = volume
	air.update_values()

/datum/pipeline/proc/network_expand(datum/pipe_network/new_network, obj/machinery/atmospherics/pipe/reference)


	if(src in new_network.line_members)
		return 0

	if(network && (network != new_network))
		return new_network.merge(network)

	new_network.line_members += src

	network = new_network

	for(var/obj/machinery/atmospherics/pipe/edge in edges)
		for(var/obj/machinery/atmospherics/result in edge.pipeline_expansion())
			if(!istype(result,/obj/machinery/atmospherics/pipe) && (result!=reference))
				result.network_expand(new_network, edge)

	return 1

/datum/pipeline/proc/return_network(obj/machinery/atmospherics/reference)
	if(!network)
		network = new /datum/pipe_network
		network.build_network(src, null)
			//technically passing these parameters should not be allowed
			//however pipe_network.build_network(..) and pipeline.network_extend(...)
			//		were setup to properly handle this case

	return network

/datum/pipeline/proc/mingle_with_turf(turf/simulated/target, mingle_volume)
	var/datum/gas_mixture/air_sample = air.remove_volume(mingle_volume)

	var/datum/gas_mixture/turf_air = target.return_air()

	equalize_gases(list(air_sample, turf_air))
	air.merge(air_sample)

	if(network)
		network.update = 1

/datum/pipeline/proc/temperature_interact(turf/target, share_volume, thermal_conductivity)
	var/total_heat_capacity = air.heat_capacity()
	var/partial_heat_capacity = total_heat_capacity*(share_volume/air.volume)

	if(istype(target, /turf/simulated))
		var/turf/simulated/modeled_location = target

		if(modeled_location.blocks_air)

			if((modeled_location.heat_capacity>0) && (partial_heat_capacity>0))
				var/delta_temperature = air.temperature - modeled_location.temperature

				var/heat = thermal_conductivity*delta_temperature* \
					(partial_heat_capacity*modeled_location.heat_capacity/(partial_heat_capacity+modeled_location.heat_capacity))

				air.temperature -= heat/total_heat_capacity
				modeled_location.temperature += heat/modeled_location.heat_capacity

		else
			var/delta_temperature = 0
			var/sharer_heat_capacity = 0

			if(modeled_location.zone)
				delta_temperature = (air.temperature - modeled_location.zone.air.temperature)
				sharer_heat_capacity = modeled_location.zone.air.heat_capacity()
			else
				delta_temperature = (air.temperature - modeled_location.air.temperature)
				sharer_heat_capacity = modeled_location.air.heat_capacity()

			var/self_temperature_delta = 0
			var/sharer_temperature_delta = 0

			if((sharer_heat_capacity>0) && (partial_heat_capacity>0))
				var/heat = thermal_conductivity*delta_temperature* \
					(partial_heat_capacity*sharer_heat_capacity/(partial_heat_capacity+sharer_heat_capacity))

				self_temperature_delta = -heat/total_heat_capacity
				sharer_temperature_delta = heat/sharer_heat_capacity
			else
				return 1

			air.temperature += self_temperature_delta

			if(modeled_location.zone)
				modeled_location.zone.air.temperature += sharer_temperature_delta
			else
				modeled_location.air.temperature += sharer_temperature_delta


	else
		if((target.heat_capacity>0) && (partial_heat_capacity>0))
			var/delta_temperature = air.temperature - target.temperature

			var/heat = thermal_conductivity*delta_temperature* \
				(partial_heat_capacity*target.heat_capacity/(partial_heat_capacity+target.heat_capacity))

			air.temperature -= heat/total_heat_capacity
	if(network)
		network.update = 1
