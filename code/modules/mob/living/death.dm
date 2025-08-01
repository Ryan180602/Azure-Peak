/mob/living/gib(no_brain, no_organs, no_bodyparts)
	var/prev_lying = lying
	if(stat != DEAD)
		death(TRUE)
	if(client)
		SSdroning.kill_droning(client)
	playsound(src.loc, pick('sound/combat/gib (1).ogg','sound/combat/gib (2).ogg'), 200, FALSE, 3)

	if(!prev_lying)
		gib_animation()

	spill_embedded_objects()
	
	spill_organs(no_brain, no_organs, no_bodyparts)

	if(!no_bodyparts)
		spread_bodyparts(no_brain, no_organs)

	spawn_gibs(no_bodyparts)
	qdel(src)

/mob/living/proc/gib_animation()
	return

/mob/living/proc/spawn_gibs()
	new /obj/effect/gibspawner/generic(drop_location(), src)

/mob/living/proc/spill_embedded_objects()
	for(var/obj/item/embedded_item as anything in simple_embedded_objects)
		simple_remove_embedded_object(embedded_item)

/mob/living/proc/spill_organs()
	return

/mob/living/proc/spread_bodyparts()
	return

/// Length of the animation in dust_animation.dmi
#define DUST_ANIMATION_TIME 1.3 SECONDS

/mob/living/dust(just_ash, drop_items, force)
	death(TRUE)

	spill_embedded_objects()

	if(drop_items)
		unequip_everything()
	
	if(buckled)
		buckled.unbuckle_mob(src, force = TRUE)

	dust_animation()
	addtimer(CALLBACK(src, PROC_REF(spawn_dust), just_ash), DUST_ANIMATION_TIME - 0.3 SECONDS)
	QDEL_IN(src, DUST_ANIMATION_TIME) // since this is sometimes called in the middle of movement, allow half a second for movement to finish, ghosting to happen and animation to play. Looks much nicer and doesn't cause multiple runtimes.

/// Animates turning into dust
/// Does not delete src afterwards, BUT it will become invisible (and grey), so ensure you handle that yourself
/atom/movable/proc/dust_animation(atom/anim_loc = src.loc)
	if(isnull(anim_loc)) // the effect breaks if we have a null loc
		return
	var/obj/effect/temp_visual/dust_animation_filter/dustfx = new(anim_loc, REF(src))
	add_filter("dust_animation", 1, displacement_map_filter(render_source = dustfx.render_target, size = 256))
	add_filter("dust_color", 1, color_matrix_filter())
	transition_filter("dust_color", color_matrix_filter(list(0.33,0.33,0.33,0, 0.59,0.59,0.59,0, 0.11,0.11,0.11,0, 0,0,0,1, 0,0,0,0)), DUST_ANIMATION_TIME - 0.3 SECONDS)
	animate(src, alpha = 0, time = DUST_ANIMATION_TIME - 0.1 SECONDS, easing = SINE_EASING | EASE_IN)

/// Holds the dust animation filter effect, so we can animate it
/obj/effect/temp_visual/dust_animation_filter
	icon = 'icons/mob/dust_animation.dmi'
	icon_state = "dust.1"
	duration = DUST_ANIMATION_TIME
	randomdir = FALSE

/obj/effect/temp_visual/dust_animation_filter/Initialize(mapload, anim_id = "random_default_anti_collision_text")
	. = ..()
	// we manually animate this, rather than just using an animated icon state or flick, to work around byond animated state memes
	// (normally, all animated icon states are synced to the same time, which would bad here)
	for(var/i in 2 to duration)
		animate(src, time = 1, icon_state = "dust.[i]", flags = ANIMATION_CONTINUE)
	render_target = "*dust-[anim_id]"

#undef DUST_ANIMATION_TIME

/mob/living/proc/spawn_dust(just_ash = FALSE)
	for(var/i in 1 to 3)
		new /obj/item/ash(loc)


/mob/living/death(gibbed, nocutscene = FALSE)
	var/was_dead_before = stat == DEAD
	stat = DEAD
	unset_machine()
	timeofdeath = world.time
	tod = station_time_timestamp()
//	var/turf/T = get_turf(src)
	for(var/obj/item/I in contents)
		I.on_mob_death(src, gibbed)
//	if(mind && mind.name && mind.active && !istype(T.loc, /area/ctf))
//		deadchat_broadcast(" has died at <b>[get_area_name(T)]</b>.", "<b>[mind.name]</b>", follow_target = src, turf_target = T, message_type=DEADCHAT_DEATHRATTLE)
//	if(mind)
//		mind.store_memory("Time of death: [tod]", 0)
	GLOB.alive_mob_list -= src
	if(!gibbed && !was_dead_before)
		GLOB.dead_mob_list += src

//	stop_all_loops()
	SSdroning.kill_rain(src.client)
	SSdroning.kill_loop(src.client)
	SSdroning.kill_droning(src.client)
	if(!nocutscene)
		src.playsound_local(src, 'sound/misc/deth.ogg', 100)

	set_drugginess(0)
	set_disgust(0)
	SetSleeping(0, 0)
	reset_perspective(null)
	reload_fullscreen()
	update_action_buttons_icon()
	update_damage_hud()
	update_health_hud()
	update_mobility()
	stop_pulling()

	. = ..()

	SEND_SIGNAL(src, COMSIG_LIVING_DEATH, gibbed) 
	if(client)
		client.move_delay = initial(client.move_delay)
		if(!nocutscene)
			var/atom/movable/screen/gameover/hog/H = new()
			H.layer = SPLASHSCREEN_LAYER+0.1
			client.screen += H
			H.Fade()
			addtimer(CALLBACK(H, TYPE_PROC_REF(/atom/movable/screen/gameover, Fade), TRUE), 100)
//		flick("gameover",H)
//		addtimer(CALLBACK(H, TYPE_PROC_REF(/atom/movable/screen/gameover, Fade)), 29)
		mob_timers["lastdied"] = world.time
//		addtimer(CALLBACK(client, PROC_REF(ghostize), 1, src), 150)
		add_client_colour(/datum/client_colour/monochrome)
		client.verbs.Add(GLOB.ghost_verbs)

	for(var/s in ownedSoullinks)
		var/datum/soullink/S = s
		S.ownerDies(gibbed)
	for(var/s in sharedSoullinks)
		var/datum/soullink/S = s
		S.sharerDies(gibbed)

//	for(var/datum/death_tracker/D in target.death_trackers)

	if(!gibbed && !QDELETED(src) && rot_type)
		LoadComponent(rot_type)

	clear_typing_indicator()

	// AZURE EDIT BEGIN: necra acolyte/priest deathsight trait
	// this was a player that just died, so do the honors
	if (client)
		if (!gibbed)
			var/locale = prepare_deathsight_message()
			for (var/mob/living/player in GLOB.player_list)
				if (player.stat == DEAD || isbrain(player))
					continue
				if (HAS_TRAIT(player, TRAIT_DEATHSIGHT))
					if (HAS_TRAIT(player, TRAIT_CABAL))
						to_chat(player, span_warning("I feel the faint passage of disjointed life essence as it flees [locale]."))
					else
						to_chat(player, span_warning("Veiled whispers herald the Undermaiden's gaze in my mind's eye as it turn towards [locale] for but a brief, singular moment."))
	// AZURE EDIT END

	return TRUE

/mob/living/proc/prepare_deathsight_message()
	var/area/A = get_area(src)
	if(!A)
		return "a locale wreathed in enigmatic fog" // fallback if we can't find the area somehow??
	return A.deathsight_message
