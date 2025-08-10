/datum/outfit/striketeam/nukeops

	outfit_name = "Nuclear Operative"

	backpack_types = list(
		BACKPACK_STRING = /obj/item/weapon/storage/backpack/security,
		SATCHEL_NORM_STRING = /obj/item/weapon/storage/backpack/satchel_sec,
		SATCHEL_ALT_STRING = /obj/item/weapon/storage/backpack/satchel_sec,
		MESSENGER_BAG_STRING = /obj/item/weapon/storage/backpack/messenger/sec,
	)

	items_to_spawn = list(
		// Human
		"Default" = list(
			slot_ears_str = /obj/item/device/radio/headset/syndicate,
			slot_w_uniform_str = /obj/item/clothing/under/syndicate/holomap,
			slot_shoes_str = /obj/item/clothing/shoes/combat,
			slot_wear_suit_str = /obj/item/clothing/suit/armor/bulletproof,
			slot_gloves_str = /obj/item/clothing/gloves/combat,
			slot_head_str = /obj/item/clothing/head/helmet/tactical/swat,
			slot_wear_id_str = /obj/item/weapon/card/id/syndicate,
		),

		// Plasmaman
		/datum/species/plasmaman/ = list(
			slot_ears_str = /obj/item/device/radio/headset/syndicate,
			slot_w_uniform_str = /obj/item/clothing/under/syndicate/holomap,
			slot_shoes_str = /obj/item/clothing/shoes/combat,

			slot_wear_suit_str = /obj/item/clothing/suit/space/plasmaman/nuclear, // Different
			slot_wear_mask_str = /obj/item/clothing/mask/breath,

			slot_gloves_str = /obj/item/clothing/gloves/combat,
			slot_head_str = /obj/item/clothing/head/helmet/space/plasmaman/nuclear, // Different
			slot_wear_id_str = /obj/item/weapon/card/id/syndicate,
		),

		/datum/species/vox/ = list(
			slot_ears_str = /obj/item/device/radio/headset/syndicate,
			slot_w_uniform_str = /obj/item/clothing/under/syndicate/holomap,
			slot_shoes_str = /obj/item/clothing/shoes/combat,
			slot_wear_suit_str = /obj/item/clothing/suit/armor/bulletproof,
			slot_wear_mask_str = /obj/item/clothing/mask/breath/vox, // Different
			slot_gloves_str = /obj/item/clothing/gloves/combat,
			slot_head_str = /obj/item/clothing/head/helmet/tactical/swat,
			slot_wear_id_str = /obj/item/weapon/card/id/syndicate,
		),
	)

	equip_survival_gear = list(
		/datum/species/human = /obj/item/weapon/storage/box/survival/nuke/human,
		/datum/species/plasmaman = /obj/item/weapon/storage/box/survival/nuke/human,
		/datum/species/diona = /obj/item/weapon/storage/box/survival/nuke/human,
		/datum/species/insectoid = /obj/item/weapon/storage/box/survival/nuke/human,
		/datum/species/vox = /obj/item/weapon/storage/box/survival/nuke/vox,
	)

	implant_types = list(
		/obj/item/weapon/implant/explosive/nuclear,
	)

/datum/outfit/striketeam/nukeops/spawn_id(var/mob/living/carbon/human/H, rank)
	return // Nuke ops have anonymous ID cards.

/datum/outfit/striketeam/nukeops/post_equip(var/mob/living/carbon/human/H)
	..()
	equip_accessory(H, /obj/item/clothing/accessory/wristwatch/black, /obj/item/clothing/under, 5)
	var/obj/item/device/radio/R = H.ears
	R.set_frequency(SYND_FREQ)
	if(H.mind.GetRole(NUKE_OP_LEADER))
		H.equip_to_slot_or_del(new /obj/item/device/modkit/syndi_commander(H), slot_in_backpack)
	if (H.active_genes.len > 0)
		to_chat(H, "The Syndicate has provided you with a ryetalyn pill to cure your genetic defects. Use it at your own discretion.")
		var/obj/item/weapon/reagent_containers/pill/ryetalyn/pill = new (H)
		if (!H.equip_to_slot_or_drop(pill, slot_l_store))
			H.put_in_hands(pill)

/datum/outfit/striketeam/nukeops/pre_equip(var/mob/living/carbon/human/H)
	if(H.overeatduration) //We need to do this here and now, otherwise a lot of gear will fail to spawn
		to_chat(H, "<span class='notice'>Your intensive physical training to become a Nuclear Operative has paid off and made you fit again!</span>")
		H.overeatduration = 0 //Fat-B-Gone
		if(H.nutrition > 400) //We are also overeating nutriment-wise
			H.nutrition = 400 //Fix that
		H.mutations.Remove(M_FAT)
		H.update_mutantrace(0)
		H.update_mutations(0)
		H.update_inv_w_uniform(0)
		H.update_inv_wear_suit()
	return ..()
