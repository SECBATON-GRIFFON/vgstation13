/obj/structure/window/barricade/drywall
    name = "wall"
    desc = "A huge chunk of metal used to separate rooms."
    icon = 'icons/obj/structures.dmi'
    icon_state = "drywall"
    anchored = 1
    opacity = 1 //Not transparent
    health = 20 //Enough to punch a hole in
    plane = EFFECTS_PLANE
    layer = ABOVE_PROJECTILE_LAYER
    pass_flags_self = 0 //Pretend to be a wall
    materialtype = /obj/item/stack/sheet/metal
    pryable = FALSE
    fire_temp_threshold = MELTPOINT_STEEL
    fire_volume_mod = 500
    var/image/override_image //As viewed by client from a dir
    var/obj/effect/border_opacity/border_opacity

/obj/structure/window/barricade/drywall/New()
    ..()
    border_opacity = new /obj/effect/border_opacity(get_step(loc,dir))

/obj/structure/window/barricade/drywall/Destroy()
    qdel(border_opacity)
    border_opacity = null
    ..()

/obj/structure/window/barricade/drywall/attackby(obj/item/weapon/W as obj, mob/user as mob)
    if(iswelder(W) && !busy) //Only way to deconstruct
        W.playtoolsound(loc, 75)
        user.visible_message("<span class='warning'>[user] begins slicing through \the [src].</span>", \
        "<span class='notice'>You begin slicing through \the [src].</span>", \
        "<span class='warning'>You hear welding noises.</span>")
        busy = 1

        if(do_after(user, src, 30)) //Takes less than barricade, is flimsier
            playsound(loc, 'sound/items/Deconstruct.ogg', 75, 1)
            user.visible_message("<span class='warning'>[user] slices through \the [src].</span>", \
            "<span class='notice'>You slice through \the [src].</span>", \
            "<span class='warning'>You hear welding noises.</span>")
            busy = 0
            qdel(src)
            return
        else
            busy = 0
    else
        ..() //Barricade checks

/obj/effect/border_opacity
    opacity = 1