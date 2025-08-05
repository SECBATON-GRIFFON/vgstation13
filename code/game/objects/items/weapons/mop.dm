/obj/item/weapon/mop
	desc = "The world of janitalia wouldn't be complete without a mop."
	name = "mop"
	icon = 'icons/obj/janitor.dmi'
	icon_state = "mop"
	hitsound = "sound/weapons/whip.ogg"
	force = 3.0
	throwforce = 10.0
	throw_speed = 5
	throw_range = 3
	w_class = W_CLASS_MEDIUM
	w_type = RECYK_WOOD
	flammable = TRUE
	flags = FPRINT
	attack_verb = list("mops", "bashes", "bludgeons", "whacks", "slaps", "whips")

/obj/item/weapon/mop/New()
	. = ..()
	create_reagents(50)
	mop_list.Add(src)

/obj/item/weapon/mop/Destroy()
	mop_list.Remove(src)
	..()

/obj/item/weapon/mop/update_icon()
	..()
	overlays.len = 0
	if (reagents.total_volume >= 1)
		var/image/covering = image(icon, "mop-reagent")
		covering.icon += mix_color_from_reagents(reagents.reagent_list)
		covering.alpha = mix_alpha_from_reagents(reagents.reagent_list)
		overlays += covering

/obj/item/weapon/mop/proc/clean(turf/simulated/A as turf)
	for(var/obj/effect/O in A)
		if(iscleanaway(O))
			qdel(O)

	if (A.advanced_graffiti)
		A.overlays -= A.advanced_graffiti_overlay
		A.advanced_graffiti_overlay = null
		qdel(A.advanced_graffiti)

	reagents.reaction(A,1,10) //Mops magically make chems ten times more efficient than usual, aka equivalent of 50 units of whatever you're using
	A.clean_blood()
	playsound(src, get_sfx("mop"), 25, 1)

/obj/effect/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W, /obj/item/weapon/mop))
		return
	..()

/obj/item/weapon/mop/afterattack(atom/A, mob/user as mob)
	if(!user.Adjacent(A))
		return
	if(A.mop_act(src, user))
		update_icon()
		return
	if(!src)
		return
	update_icon()

/mob/living/mop_act(obj/item/weapon/mop/M, mob/user as mob)
	if(!(M.reagents.total_volume < 1)) //Slap slap slap
		visible_message("<span class='danger'>[user] [ishuman(src) ? "hits [src] in the [parse_zone(user.zone_sel.selecting)] with" : "covers [src] in"] the mop's contents</span>")
		reagents.reaction(src,1,10, zone_sels = list(user.zone_sel.selecting)) //I hope you like my polyacid cleaner mix
		reagents.clear_reagents()

/turf/mop_act(obj/item/weapon/mop/M, mob/user as mob)
	if(liquid && liquid.reagents && M.reagents)
		if(M.reagents.total_volume < 1)
			if(liquid.reagents.total_volume)
				user.visible_message("<span class='notice'>[user] soaks up \the [src.liquid].</span>", "<span class='notice'>You soak \the [src.liquid].</span>")
				liquid.reagents.trans_to(M, 25 - M.reagents.total_volume)
			else
				to_chat(user, "<span class='notice'>Your mop is dry!</span>")
			return
		if(M.reagents.has_reagent(WATER) && liquid.reagents.total_volume < 50)
			user.visible_message("<span class='[arcanetampered ? "sinister" : "warning"]'>[user] cleans \the [src)].</span>", "<span class='[arcanetampered ? "sinister" : "notice"]'>You clean \the [get_turf(A)].</span>")
			user.delayNextAttack(10)
			if(arcanetampered)
				var/dirttype = pick(subtypesof(/obj/effect/decal/cleanable))
				new dirttype(get_turf(A))
			else
				M.clean(src)
			add_to_liquid(WATER,50 - reagents.total_volume)
			M.reagents.remove_any(1) //Might be a tad wonky with "special mop mixes", but fuck it