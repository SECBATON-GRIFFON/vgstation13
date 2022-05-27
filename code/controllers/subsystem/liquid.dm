var/datum/subsystem/liquid/SSliquid

var/list/datum/liquid/puddles = list()

/datum/subsystem/liquid
	name          = "Machinery"
	wait          = SS_WAIT_LIQUID
	flags         = SS_NO_INIT | SS_KEEP_TIMING
	priority      = SS_PRIORITY_LIQUID
	display_order = SS_DISPLAY_LIQUID

	var/list/currentrun


/datum/subsystem/liquid/New()
	NEW_SS_GLOBAL(SSliquid)


/datum/subsystem/liquid/stat_entry(var/msg)
	if (msg)
		return ..()

	..("L:[global.puddles.len]")


// This is to allow the near identical fast liquids process to use it.
/datum/subsystem/liquid/proc/get_currenrun()
	return puddles.Copy()


/datum/subsystem/liquid/fire(resumed = FALSE)
	if (!resumed)
		currentrun = get_currenrun()

	while (currentrun.len)
		var/obj/effect/overlay/puddle/P = currentrun[currentrun.len]
		currentrun.len--

		if (!P || P.gcDestroyed)
			continue

		P.process()

		if (MC_TICK_CHECK)
			return
