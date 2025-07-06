/**********************Mine areas**************************/

/area/mine
	icon_state = "mining"
	music = 'sound/ambience/song_game.ogg'

	general_area = /area/mine
	general_area_name = "Mining Station"

/area/mine/explored
	name = "Mine"
	icon_state = "explored"

/area/mine/unexplored
	name = "Mine"
	icon_state = "unexplored"
	holomap_draw_override = HOLOMAP_DRAW_FULL

//TODO: Make all these types inherit from /area/mining_outpost/ instead.
/area/mining_outpost
	no_air = FALSE

/area/mine/lobby
	name = "Mining station"
	holomap_color = HOLOMAP_AREACOLOR_CARGO
	parent_type = /area/mining_outpost

/area/mine/storage
	name = "Mining station Storage"
	holomap_color = HOLOMAP_AREACOLOR_CARGO
	parent_type = /area/mining_outpost

/area/mine/production
	name = "Mining Station Starboard Wing"
	icon_state = "mining_production"
	holomap_color = HOLOMAP_AREACOLOR_CARGO
	parent_type = /area/mining_outpost

/area/mine/abandoned
	name = "Abandoned Mining Station"
	parent_type = /area/mining_outpost

/area/mine/living_quarters
	name = "Mining Station Port Wing"
	icon_state = "mining_living"
	holomap_color = HOLOMAP_AREACOLOR_CARGO
	parent_type = /area/mining_outpost

/area/mine/eva
	name = "Mining Station EVA"
	icon_state = "mining_eva"
	holomap_color = HOLOMAP_AREACOLOR_CARGO
	parent_type = /area/mining_outpost

/area/mine/maintenance
	name = "Mining Station Communications"
	holomap_color = HOLOMAP_AREACOLOR_COMMAND
	ambient_sounds = list(
		/datum/ambience/tcomms1,
		/datum/ambience/tcomms2,
		/datum/ambience/tcomms3)
	parent_type = /area/mining_outpost

/area/mine/cafeteria
	name = "Mining station Cafeteria"
	holomap_color = HOLOMAP_AREACOLOR_CARGO
	parent_type = /area/mining_outpost

/area/mine/hydroponics
	name = "Mining station Hydroponics"
	holomap_color = HOLOMAP_AREACOLOR_CARGO
	parent_type = /area/mining_outpost

/area/mine/sleeper
	name = "Mining station Emergency Sleeper"
	holomap_color = HOLOMAP_AREACOLOR_MEDICAL
	parent_type = /area/mining_outpost

/area/mine/north_outpost
	name = "North Mining Outpost"
	holomap_color = HOLOMAP_AREACOLOR_CARGO
	parent_type = /area/mining_outpost

/area/mine/west_outpost
	name = "West Mining Outpost"
	holomap_color = HOLOMAP_AREACOLOR_CARGO
	parent_type = /area/mining_outpost