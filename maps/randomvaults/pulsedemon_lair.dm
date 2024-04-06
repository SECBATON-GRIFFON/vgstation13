/obj/machinery/emancipation_grill/pdlair
	desc = "A holosign above reads: No insulating protection allowed beyond this point"
	obj_blacklist = list(/obj/item/clothing/gloves)

/obj/structure/cable/freepower
	var/custom_avail = 50

/obj/structure/cable/freepower/avail()
	return custom_avail
