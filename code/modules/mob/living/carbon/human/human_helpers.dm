
/mob/living/carbon/human/proc/change_name(new_name)
	real_name = new_name

/mob/living/carbon/human/restrained(ignore_grab = TRUE)
	. = ((wear_armor && wear_armor.breakouttime) || ..())

/mob/living/carbon/human/check_language_hear(language)
	if(!language)
		return
	if(wear_neck)
		if(istype(wear_neck, /obj/item/clothing/neck/roguetown/talkstone))
			return TRUE
	if(!has_language(language))
		if(has_flaw(/datum/charflaw/paranoid))
			add_stress(/datum/stressevent/paratalk)


/mob/living/carbon/human/canBeHandcuffed()
	if(get_num_arms(FALSE) >= 2)
		return TRUE
	else
		return FALSE

//gets assignment from ID or ID inside PDA or PDA itself
//Useful when player do something with computers
/mob/living/carbon/human/proc/get_assignment(if_no_id = "No id", if_no_job = "No job", hand_first = TRUE)
	return if_no_job

//gets name from ID or ID inside PDA or PDA itself
//Useful when player do something with computers
/mob/living/carbon/human/proc/get_authentification_name(if_no_id = "Unknown")
	return if_no_id

//repurposed proc. Now it combines get_id_name() and get_face_name() to determine a mob's name variable. Made into a separate proc as it'll be useful elsewhere
/mob/living/carbon/human/get_visible_name()
	var/face_name = get_face_name("")
	var/id_name = get_id_name("")
	if(name_override)
		return name_override
	if(face_name)
		if(id_name && (id_name != face_name))
			return "Unknown [(gender == FEMALE) ? "Woman" : "Man"]"
		return face_name
	if(id_name)
		return id_name
	return "Unknown"

//Returns "Unknown" if facially disfigured and real_name if not. Useful for setting name when Fluacided or when updating a human's name variable
/mob/living/carbon/human/proc/get_face_name(if_no_face="Unknown")
	if( wear_mask && (wear_mask.flags_inv&HIDEFACE) )	//Wearing a mask which hides our face, use id-name if possible
		return if_no_face
	if( head && (head.flags_inv&HIDEFACE) )
		return if_no_face		//Likewise for hats
	if( wear_neck && (wear_neck.flags_inv&HIDEFACE) )
		return if_no_face		//Likewise for hats
	if( istype(src, /mob/living/carbon/human/species/skeleton)) //SPOOKY BONES
		return real_name
	var/obj/item/bodypart/O = get_bodypart(BODY_ZONE_HEAD)
	if( !O || (HAS_TRAIT(src, TRAIT_DISFIGURED)) || !real_name || (O.skeletonized && !mind?.has_antag_datum(/datum/antagonist/lich)))	//disfigured. use id-name if possible
		return if_no_face
	return real_name

//gets name from ID or PDA itself, ID inside PDA doesn't matter
//Useful when player is being seen by other mobs
/mob/living/carbon/human/proc/get_id_name(if_no_id = "Unknown")
	. = if_no_id	//to prevent null-names making the mob unclickable
	return

/mob/living/carbon/human/IsAdvancedToolUser()
	if(HAS_TRAIT(src, TRAIT_MONKEYLIKE))
		return FALSE
	return TRUE//Humans can use guns and such

/mob/living/carbon/human/reagent_check(datum/reagent/R)
	return dna.species.handle_chemicals(R,src)
	// if it returns 0, it will run the usual on_mob_life for that reagent. otherwise, it will stop after running handle_chemicals for the species.


/mob/living/carbon/human/can_track(mob/living/user)
	if(istype(head, /obj/item/clothing/head))
		var/obj/item/clothing/head/hat = head
		if(hat.blockTracking)
			return 0

	return ..()

/mob/living/carbon/human/can_use_guns(obj/item/G)
	. = ..()
	if(G.trigger_guard == TRIGGER_GUARD_NORMAL)
		if(HAS_TRAIT(src, TRAIT_CHUNKYFINGERS))
			to_chat(src, span_warning("My meaty finger is much too large for the trigger guard!"))
			return FALSE
	if(HAS_TRAIT(src, TRAIT_NOGUNS))
		to_chat(src, span_warning("I can't bring myself to use a ranged weapon!"))
		return FALSE

/mob/living/carbon/human/get_policy_keywords()
	. = ..()
	. += "[dna.species.type]"

/mob/living/carbon/human/can_see_reagents()
	. = ..()
	if(.) //No need to run through all of this if it's already true.
		return
	if(isclothing(glasses) && (glasses.clothing_flags & SCAN_REAGENTS))
		return TRUE
	if(isclothing(head) && (head.clothing_flags & SCAN_REAGENTS))
		return TRUE
	if(isclothing(wear_mask) && (wear_mask.clothing_flags & SCAN_REAGENTS))
		return TRUE

/mob/living/carbon/human/get_punch_dmg()

	var/damage
	if(STASTR > UNARMED_DAMAGE_DEFAULT || STASTR < 10)
		damage = STASTR
	else
		damage = UNARMED_DAMAGE_DEFAULT

	var/used_str = STASTR

	var/obj/G = get_item_by_slot(SLOT_GLOVES)
	if(domhand)
		used_str = get_str_arms(used_hand)

	if(used_str >= 11)
		damage = max(damage + (damage * ((used_str - 10) * 0.3)), 1)

	if(used_str <= 9)
		damage = max(damage - (damage * ((10 - used_str) * 0.1)), 1)

	if(istype(G, /obj/item/clothing/gloves/roguetown))
		var/obj/item/clothing/gloves/roguetown/GL = G
		damage = (damage * GL.unarmed_bonus)

	if(mind)
		if(mind.has_antag_datum(/datum/antagonist/werewolf))
			return 50

	return damage

/mob/living/carbon/human/is_floor_hazard_immune()
	. = ..()
	if(dna?.species?.is_floor_hazard_immune(src))
		return TRUE


/mob/living/carbon/human/proc/do_invisibility(timeinvis)
	animate(src, alpha = 0, time = 0 SECONDS, easing = EASE_IN)
	src.mob_timers[MT_INVISIBILITY] = world.time + timeinvis
	addtimer(CALLBACK(src, TYPE_PROC_REF(/mob/living/carbon/human, update_sneak_invis), TRUE), timeinvis)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, visible_message), span_warning("[src] fades back into view."), span_notice("You become visible again.")), timeinvis)
