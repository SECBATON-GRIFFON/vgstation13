var/list/obj/structure/window/barricade/drywall/drywalls = list()

/obj/structure/window/barricade/drywall
    name = "wall"
    desc = "A huge chunk of metal used to separate rooms."
    icon = 'icons/obj/structures.dmi'
    icon_state = "drywall"
    anchored = 1
    opacity = 1 //Not transparent
    health = 20 //Enough to punch a hole in
    plane = EFFECTS_PLANE
    layer = PROJECTILE_LAYER
    pass_flags_self = 0 //Pretend to be a wall
    materialtype = /obj/item/stack/sheet/metal
    pryable = FALSE
    airtight = TRUE
    fire_temp_threshold = MELTPOINT_STEEL
    fire_volume_mod = 500
    var/image/override_image

/obj/structure/window/barricade/drywall/New()
    override_image = image('icons/turf/walls.dmi',src,"metal0")  //As viewed by client from a dir
    override_image.layer = ABOVE_PROJECTILE_LAYER
    override_image.override = TRUE //duh
    ..()
    drywalls += src

/obj/structure/window/barricade/drywall/Destroy()
    drywalls -= src
    ..()

/obj/structure/window/barricade/drywall/relativewall()
    if(canSmoothWith())
        junction = findSmoothingNeighbors()
    else
        junction = 0
    override_image.icon_state = "metal[junction]"
    return junction

/obj/structure/window/barricade/drywall/canSmoothWith()
    var/static/list/smoothables = list(
        /turf/simulated/wall,
        /obj/structure/falsewall,
        /obj/structure/window/barricade/drywall,
    )
    return smoothables

/obj/structure/window/barricade/drywall/cannotSmoothWith()
    var/static/list/unsmoothables = list(
        /turf/simulated/wall/shuttle
    )
    return unsmoothables

/obj/structure/window/barricade/drywall/isSmoothableNeighbor(atom/A, bordercheck = TRUE)
    if(!A)
        return 0
    return is_type_in_list(A, canSmoothWith()) && !(cannotSmoothWith() && (is_type_in_list(A, cannotSmoothWith())))

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

/turf/simulated/wall/proc/drywallify() //debug helper proc
    for(var/direction in cardinal)
        if(!(junction & direction))
            var/obj/structure/window/barricade/drywall/D = new(src)
            D.update_nearby_tiles() //Compel updates before
            D.change_dir(direction)
            D.update_nearby_tiles()
    ChangeTurf(dismantle_type)