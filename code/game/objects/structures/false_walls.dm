/*
 * False Walls
 */
/obj/structure/falsewall
	name = "wall"
	desc = "A huge chunk of metal used to separate rooms."
	anchored = TRUE
	icon = 'icons/turf/walls/wall.dmi'
	icon_state = "wall"
	plane = WALL_PLANE
	layer = LOW_OBJ_LAYER
	density = TRUE
	opacity = 1
	max_integrity = 100

	smoothing_flags = SMOOTH_CORNERS
	canSmoothWith = list()
	smoothing_groups = list(SMOOTH_GROUP_CLOSED_TURFS, SMOOTH_GROUP_WALLS)
/turf/closed/wall
	canSmoothWith = list(SMOOTH_GROUP_WALLS)
	can_be_unanchored = FALSE
	CanAtmosPass = ATMOS_PASS_DENSITY
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE
	rad_insulation = RAD_MEDIUM_INSULATION
	var/mineral = /obj/item/stack/sheet/metal
	var/mineral_amount = 2
	var/walltype = /turf/closed/wall
	var/girder_type = /obj/structure/girder/displaced
	var/opening = FALSE

/obj/structure/falsewall/Initialize()
	. = ..()
	air_update_turf(TRUE)

/obj/structure/falsewall/ratvar_act()
	new /obj/structure/falsewall/brass(loc)
	qdel(src)

/obj/structure/falsewall/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(opening)
		return
	. = ..()
	if(.)
		return

	opening = TRUE
	update_icon()
	if(!density)
		var/srcturf = get_turf(src)
		for(var/mob/living/obstacle in srcturf) //Stop people from using this as a shield
			opening = FALSE
			return
	addtimer(CALLBACK(src, /obj/structure/falsewall/proc/toggle_open), 5)

/obj/structure/falsewall/proc/toggle_open()
	if(!QDELETED(src))
		density = !density
		set_opacity(density)
		opening = FALSE
		update_icon()
		air_update_turf(TRUE)

/obj/structure/falsewall/update_icon_state()//Calling icon_update will refresh the smoothwalls if it's closed, otherwise it will make sure the icon is correct if it's open
	if(opening)
		if(density)
			icon_state = "fwall_opening"
			smooth = SMOOTH_FALSE
			clear_smooth_overlays()
		else
			icon_state = "fwall_closing"
	else
		if(density)
			icon_state = initial(icon_state)
			smoothing_flags = SMOOTH_CORNERS
			queue_smooth(src)
		else
			icon_state = "fwall_open"

/obj/structure/falsewall/proc/ChangeToWall(delete = 1)
	var/turf/T = get_turf(src)
	T.PlaceOnTop(walltype)
	if(delete)
		qdel(src)
	return T

/obj/structure/falsewall/attackby(obj/item/W, mob/user, params)
	if(opening)
		to_chat(user, SPAN_WARNING("You must wait until the door has stopped moving!"))
		return

	if(istype(W, /obj/item/screwdriver))
		if(density)
			var/turf/T = get_turf(src)
			if(T.density)
				to_chat(user, SPAN_WARNING("[src] is blocked!"))
				return
			if(!isfloorturf(T))
				to_chat(user, SPAN_WARNING("[src] bolts must be tightened on the floor!"))
				return
			user.visible_message(SPAN_NOTICE("[user] tightens some bolts on the wall."), SPAN_NOTICE("You tighten the bolts on the wall."))
			ChangeToWall()
		else
			to_chat(user, SPAN_WARNING("You can't reach, close it first!"))

	else if(istype(W, /obj/item/weldingtool) || istype(W, /obj/item/gun/energy/plasmacutter))
		if(W.use_tool(src, user, 0, volume=50))
			dismantle(user, TRUE)
	else
		return ..()

/obj/structure/falsewall/proc/dismantle(mob/user, disassembled=TRUE, obj/item/tool = null)
	user.visible_message("[user] dismantles the false wall.", SPAN_NOTICE("You dismantle the false wall."))
	if(tool)
		tool.play_tool_sound(src, 100)
	else
		playsound(src, 'sound/items/welder.ogg', 100, 1)
	deconstruct(disassembled)

/obj/structure/falsewall/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(disassembled)
			new girder_type(loc)
		if(mineral_amount)
			for(var/i in 1 to mineral_amount)
				new mineral(loc)
	qdel(src)

/obj/structure/falsewall/get_dumping_location(obj/item/storage/source,mob/user)
	return null

/obj/structure/falsewall/examine_status(mob/user) //So you can't detect falsewalls by examine.
	to_chat(user, SPAN_NOTICE("The outer plating is <b>welded</b> firmly in place."))
	return null

/*
 * False R-Walls
 */

/obj/structure/falsewall/reinforced
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to separate rooms."
	icon = 'icons/turf/walls/reinforced_wall.dmi'
	icon_state = "r_wall"
	walltype = /turf/closed/wall/r_wall
	mineral = /obj/item/stack/sheet/plasteel

/obj/structure/falsewall/reinforced/examine_status(mob/user)
	to_chat(user, SPAN_NOTICE("The outer <b>grille</b> is fully intact."))
	return null

/obj/structure/falsewall/reinforced/attackby(obj/item/tool, mob/user)
	..()
	if(istype(tool, /obj/item/wirecutters))
		dismantle(user, TRUE, tool)

/*
 * Uranium Falsewalls
 */

/obj/structure/falsewall/uranium
	name = "uranium wall"
	desc = "A wall with uranium plating. This is probably a bad idea."
	icon = 'icons/turf/walls/uranium_wall.dmi'
	icon_state = "uranium"
	mineral = /obj/item/stack/sheet/mineral/uranium
	walltype = /turf/closed/wall/mineral/uranium
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_URANIUM_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_URANIUM_WALLS)
	var/active = null
	var/last_event = 0
	
/obj/structure/falsewall/uranium/attackby(obj/item/W, mob/user, params)
	radiate()
	return ..()

/obj/structure/falsewall/uranium/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	radiate()
	. = ..()

/obj/structure/falsewall/uranium/proc/radiate()
	if(!active)
		if(world.time > last_event+15)
			active = 1
			radiation_pulse(src, 150)
			for(var/turf/closed/wall/mineral/uranium/T in orange(1,src))
				T.radiate()
			last_event = world.time
			active = null
			return
	return
/*
 * Other misc falsewall types
 */

/obj/structure/falsewall/gold
	name = "gold wall"
	desc = "A wall with gold plating. Swag!"
	icon = 'icons/turf/walls/gold_wall.dmi'
	icon_state = "gold"
	mineral = /obj/item/stack/sheet/mineral/gold
	walltype = /turf/closed/wall/mineral/gold
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_GOLD_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_GOLD_WALLS)

/obj/structure/falsewall/silver
	name = "silver wall"
	desc = "A wall with silver plating. Shiny."
	icon = 'icons/turf/walls/silver_wall.dmi'
	icon_state = "silver"
	mineral = /obj/item/stack/sheet/mineral/silver
	walltype = /turf/closed/wall/mineral/silver
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_SILVER_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_SILVER_WALLS)

/obj/structure/falsewall/diamond
	name = "diamond wall"
	desc = "A wall with diamond plating. You monster."
	icon = 'icons/turf/walls/diamond_wall.dmi'
	icon_state = "diamond"
	mineral = /obj/item/stack/sheet/mineral/diamond
	walltype = /turf/closed/wall/mineral/diamond
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_DIAMOND_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_DIAMOND_WALLS)
	max_integrity = 800

/obj/structure/falsewall/plasma
	name = "plasma wall"
	desc = "A wall with plasma plating. This is definitely a bad idea."
	icon = 'icons/turf/walls/plasma_wall.dmi'
	icon_state = "plasma"
	mineral = /obj/item/stack/sheet/mineral/plasma
	walltype = /turf/closed/wall/mineral/plasma
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_PLASMA_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_PLASMA_WALLS)

/obj/structure/falsewall/plasma/attackby(obj/item/W, mob/user, params)
	if(W.get_temperature() > 300)
		var/turf/T = get_turf(src)
		message_admins("Plasma falsewall ignited by [ADMIN_LOOKUPFLW(user)] in [ADMIN_VERBOSEJMP(T)]")
		log_game("Plasma falsewall ignited by [key_name(user)] in [AREACOORD(T)]")
		burnbabyburn()
	else
		return ..()

/obj/structure/falsewall/plasma/proc/burnbabyburn(user)
	playsound(src, 'sound/items/welder.ogg', 100, 1)
	atmos_spawn_air("plasma=400;TEMP=1000")
	new /obj/structure/girder/displaced(loc)
	qdel(src)

/obj/structure/falsewall/plasma/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature > 300)
		burnbabyburn()

/obj/structure/falsewall/bananium
	name = "bananium wall"
	desc = "A wall with bananium plating. Honk!"
	icon = 'icons/turf/walls/bananium_wall.dmi'
	icon_state = "bananium"
	mineral = /obj/item/stack/sheet/mineral/bananium
	walltype = /turf/closed/wall/mineral/bananium
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_BANANIUM_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_BANANIUM_WALLS)


/obj/structure/falsewall/sandstone
	name = "sandstone wall"
	desc = "A wall with sandstone plating. Rough."
	icon = 'icons/turf/walls/sandstone_wall.dmi'
	icon_state = "sandstone"
	mineral = /obj/item/stack/sheet/mineral/sandstone
	walltype = /turf/closed/wall/mineral/sandstone
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_SANDSTONE_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_SANDSTONE_WALLS)

/obj/structure/falsewall/wood
	name = "wooden wall"
	desc = "A wall with wooden plating. Stiff."
	icon = 'icons/turf/walls/wood_wall.dmi'
	icon_state = "wood"
	mineral = /obj/item/stack/sheet/mineral/wood
	walltype = /turf/closed/wall/mineral/wood
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_WOOD_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_WOOD_WALLS)

/obj/structure/falsewall/bamboo
	name = "bamboo wall"
	desc = "A wall with bamboo finish. Zen."
	icon = 'icons/turf/walls/bamboo_wall.dmi'
	icon_state = "bamboo"
	mineral = /obj/item/stack/sheet/mineral/bamboo
	walltype = /turf/closed/wall/mineral/bamboo
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_BAMBOO_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_BAMBOO_WALLS)


/obj/structure/falsewall/iron
	name = "rough metal wall"
	desc = "A wall with rough metal plating."
	icon = 'icons/turf/walls/iron_wall.dmi'
	icon_state = "iron"
	mineral = /obj/item/stack/rods
	mineral_amount = 5
	walltype = /turf/closed/wall/mineral/iron
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_IRON_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_IRON_WALLS)

/obj/structure/falsewall/abductor
	name = "alien wall"
	desc = "A wall with alien alloy plating."
	icon = 'icons/turf/walls/abductor_wall.dmi'
	icon_state = "abductor"
	mineral = /obj/item/stack/sheet/mineral/abductor
	walltype = /turf/closed/wall/mineral/abductor
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_ABDUCTOR_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_ABDUCTOR_WALLS)

/obj/structure/falsewall/titanium
	name = "wall"
	desc = "A light-weight titanium wall used in shuttles."
	icon = 'icons/turf/walls/shuttle_wall.dmi'
	icon_state = "shuttle"
	mineral = /obj/item/stack/sheet/mineral/titanium
	walltype = /turf/closed/wall/mineral/titanium
	smoothing_flags = SMOOTH_CORNERS
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_TITANIUM_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_TITANIUM_WALLS, SMOOTH_GROUP_AIRLOCK, SMOOTH_GROUP_SHUTTLE_PARTS)

/obj/structure/falsewall/plastitanium
	name = "wall"
	desc = "An evil wall of plasma and titanium."
	icon = 'icons/turf/walls/plastitanium_wall.dmi'
	icon_state = "shuttle"
	mineral = /obj/item/stack/sheet/mineral/plastitanium
	walltype = /turf/closed/wall/mineral/plastitanium
	smoothing_flags = SMOOTH_CORNERS
	smoothing_groups = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_PLASTITANIUM_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_PLASTITANIUM_WALLS, SMOOTH_GROUP_AIRLOCK, SMOOTH_GROUP_SHUTTLE_PARTS)

/obj/structure/falsewall/brass
	name = "clockwork wall"
	desc = "A huge chunk of warm metal. The clanging of machinery emanates from within."
	icon = 'icons/turf/walls/clockwork_wall.dmi'
	icon_state = "clockwork_wall"
	resistance_flags = FIRE_PROOF | ACID_PROOF
	mineral_amount = 1
	canSmoothWith = list(/obj/effect/clockwork/overlay/wall, /obj/structure/falsewall/brass)
	girder_type = /obj/structure/destructible/clockwork/wall_gear/displaced
	walltype = /turf/closed/wall/clockwork
	mineral = /obj/item/stack/tile/brass

/obj/structure/falsewall/brass/New(loc)
	..()
	var/turf/T = get_turf(src)
	new /obj/effect/temp_visual/ratvar/wall/false(T)
	new /obj/effect/temp_visual/ratvar/beam/falsewall(T)
	change_construction_value(4)

/obj/structure/falsewall/brass/Destroy()
	change_construction_value(-4)
	return ..()

/obj/structure/falsewall/brass/ratvar_act()
	if(GLOB.ratvar_awakens)
		obj_integrity = max_integrity
