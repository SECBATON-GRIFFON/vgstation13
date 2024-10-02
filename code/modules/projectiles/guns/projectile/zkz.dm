/obj/item/weapon/gun/projectile/zkz
    name = "\improper ZKZ transactional rifle"
    desc = "Primordial weapon attuned to the beating heart of the financial system."
    fire_sound = 'sound/weapons/mosin.ogg'
    icon = 'icons/obj/biggun.dmi'
    icon_state = "mosinlarge"
    item_state = null
    inhand_states = list("left_hand" = 'icons/mob/in-hand/left/guninhands_left.dmi', "right_hand" = 'icons/mob/in-hand/right/guninhands_right.dmi')
    max_shells = 30
    w_class = W_CLASS_LARGE
    force = 10
    flags = FPRINT
    siemens_coefficient = 1
    slot_flags = SLOT_BACK
    origin_tech = Tc_COMBAT + "=5;" + Tc_MATERIALS + "=2;" + Tc_SYNDICATE + "=5"
    gun_flags = 0
    mech_flags = MECH_SCAN_FAIL
    var/shotsleft = 30
    
/obj/item/weapon/gun/projectile/zkz/getAmmo()
    return shotsleft

/obj/item/weapon/gun/projectile/zkz/getSpent()
    return max_shells - shotsleft

/obj/item/weapon/gun/projectile/zkz/process_chambered()
    if(in_chamber)
        return 1
    else if(shotsleft)
        in_chamber = new /obj/item/projectile/bullet/a76239mm_financial(src)
        var/mob/M = loc
        if(istype(M))
            var/obj/item/weapon/card/id/ourID = M.get_item_by_slot(slot_wear_id)
            if(!istype(ourID))
                ourID = ourID.GetID()
            if(istype(ourID) && ourID.virtual_wallet)
                switch(ourID.virtual_wallet.money)
                    if(0 to 100)
                        in_chamber.damage = 1
                    if(100 to 1000)
                        in_chamber.damage = 10
                    if(1000 to 10000)
                        in_chamber.damage = 25
                    if(10000 to 100000)
                        in_chamber.damage = 50
                    if(100000 to 1000000)
                        in_chamber.damage = 75
                    if(1000000 to INFINITY)
                        in_chamber.damage = 20000
        shotsleft--
        return 1
    return 0