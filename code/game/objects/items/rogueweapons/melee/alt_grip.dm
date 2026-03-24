/obj/item/proc/has_altgrip_modes()
	return length(alt_grips) > 0

/obj/item/proc/get_altgrip_names(mob/living/carbon/user)
	if(!has_altgrip_modes())
		return null
	var/list/grip_names = list()
	for(var/index in 1 to length(alt_grips))
		var/datum/alt_grip/grip = get_alt_grip_state(index)
		if(!grip?.can_be_used_by(src, user))
			continue
		if(!grip?.name)
			continue
		var/grip_name = grip.name
		var/required_traits_text = grip.get_required_traits_text()
		if(required_traits_text)
			grip_name += span_info(" [required_traits_text]")
		if(grip.is_two_handed(src))
			grip_name += span_danger(" (2H)")
		grip_names += grip_name
	if(!length(grip_names))
		return null
	return jointext(grip_names, ", ")

/obj/item/proc/get_altgrip_intents()
	if(!current_alt_grip)
		return possible_item_intents
	var/list/intents = current_alt_grip.get_grip_intents(src)
	if(length(intents))
		return intents
	return possible_item_intents


/obj/item/proc/get_altgrip_shift_message()
	if(!current_alt_grip)
		return null
	var/grip_name = current_alt_grip.name
	var/two_handed_text = ""
	if(current_alt_grip.is_two_handed(src))
		two_handed_text = " with both hands"
	if(grip_name)
		return "I shift [src] into a [grip_name][two_handed_text]."

/obj/item/proc/get_alt_grip_state(index)
	if(!length(alt_grips))
		return null
	var/entry = alt_grips[index]
	if(ispath(entry, /datum/alt_grip))
		entry = new entry()
		alt_grips[index] = entry
	if(istype(entry, /datum/alt_grip))
		return entry
	return null

/obj/item/proc/set_alt_grip_state(index)
	if(!length(alt_grips))
		return FALSE
	var/datum/alt_grip/state = get_alt_grip_state(index)
	if(!state)
		return FALSE
	clear_alt_grip_state()
	current_alt_grip = state
	current_alt_grip_index = index
	state.apply_to(src)
	wielded = state.is_two_handed(src)
	clear_alt_grip_onmobprops()
	update_force_dynamic()
	update_wdefense_dynamic()
	return TRUE

/obj/item/proc/clear_alt_grip_state()
	if(current_alt_grip)
		current_alt_grip.remove_from(src)
	if(length(alt_grip_restore_vars))
		for(var/var_name in alt_grip_restore_vars)
			vars[var_name] = alt_grip_restore_vars[var_name]
	alt_grip_restore_vars = null
	current_alt_grip = null
	current_alt_grip_index = 0
	clear_alt_grip_onmobprops()
	update_force_dynamic()
	update_wdefense_dynamic()

/obj/item/proc/clear_alt_grip_onmobprops()
	if(!onprop)
		return
	onprop.Remove("altgrip")


/datum/alt_grip
	var/name = "alternate grip"
	/// Whether this grip state counts as being wielded with both hands.
	var/two_handed = FALSE
	/// Intents exposed while this grip state is active.
	var/list/grip_intents
	/// Traits that allow a mob to use this grip state. Null means unrestricted.
	var/list/trait_applied = null
	/// On-mob sprite prop overrides keyed by the requested getonmobprop tag.
	var/list/onmobprop_overrides
	/// Map of item var names to override values applied while this state is active.
	var/list/var_overrides

/datum/alt_grip/proc/get_grip_intents(obj/item/source)
	if(!grip_intents)
		return null
	return grip_intents.Copy()

/datum/alt_grip/proc/is_two_handed(obj/item/source)
	return two_handed

/datum/alt_grip/proc/can_be_used_by(obj/item/source, mob/living/carbon/user)
	if(!length(trait_applied))
		return TRUE
	if(!user)
		return FALSE
	for(var/trait in trait_applied)
		if(HAS_TRAIT(user, trait))
			return TRUE
	return FALSE

/datum/alt_grip/proc/get_required_traits_text()
	if(!length(trait_applied))
		return null
	return "([jointext(trait_applied, "/")])"

/datum/alt_grip/proc/getonmobprop(obj/item/source, tag)
	if(!tag || !onmobprop_overrides)
		return null
	var/list/prop = onmobprop_overrides[tag]
	if(!islist(prop))
		return null
	return prop.Copy()

/datum/alt_grip/proc/get_var_overrides(obj/item/source)
	if(!var_overrides)
		return null
	return var_overrides.Copy()

/datum/alt_grip/proc/apply_to(obj/item/source)
	var/list/overrides = get_var_overrides(source)
	if(!length(overrides))
		return
	if(!source.alt_grip_restore_vars)
		source.alt_grip_restore_vars = list()
	for(var/var_name in overrides)
		if(!(var_name in source.alt_grip_restore_vars))
			source.alt_grip_restore_vars[var_name] = source.vars[var_name]
		var/new_value = overrides[var_name]
		if(islist(new_value))
			var/list/override_list = new_value
			source.vars[var_name] = override_list.Copy()
		else
			source.vars[var_name] = new_value

/datum/alt_grip/proc/remove_from(obj/item/source)
	return


/datum/alt_grip/mordhau
	name = "mordhau grip"
	two_handed = TRUE

/datum/alt_grip/mordhau/sword
	grip_intents = list(
		/datum/intent/sword/strike,
		/datum/intent/sword/bash,
		/datum/intent/effect/daze
	)
	onmobprop_overrides = list(
		"altgrip" = list(
			"shrink" = 0.6,
			"sx" = 2,
			"sy" = 3,
			"nx" = -7,
			"ny" = 1,
			"wx" = -8,
			"wy" = 0,
			"ex" = 8,
			"ey" = -1,
			"northabove" = 0,
			"southabove" = 1,
			"eastabove" = 1,
			"westabove" = 0,
			"nturn" = -135,
			"sturn" = -35,
			"wturn" = 45,
			"eturn" = 145,
			"nflip" = 8,
			"sflip" = 8,
			"wflip" = 1,
			"eflip" = 0,
		),
	)
	var_overrides = list(
		"wlength" = WLENGTH_SHORT
	)

/datum/alt_grip/mordhau/broadsword
	grip_intents = list(
		/datum/intent/sword/strike,
		/datum/intent/sword/bash,
		/datum/intent/effect/daze,
		/datum/intent/sword/cut/broadsword
	)
	onmobprop_overrides = list(
		"altgrip" = list(
			"shrink" = 0.6,
			"sx" = 2,
			"sy" = 3,
			"nx" = -7,
			"ny" = 1,
			"wx" = -8,
			"wy" = 0,
			"ex" = 8,
			"ey" = -1,
			"northabove" = 0,
			"southabove" = 1,
			"eastabove" = 1,
			"westabove" = 0,
			"nturn" = -135,
			"sturn" = -35,
			"wturn" = 45,
			"eturn" = 145,
			"nflip" = 8,
			"sflip" = 8,
			"wflip" = 1,
			"eflip" = 0,
		),
	)

/datum/alt_grip/mordhau/greatsword
	grip_intents = list(
		/datum/intent/sword/strike,
		/datum/intent/sword/bash,
		/datum/intent/effect/daze
	)
	onmobprop_overrides = list(
		"altgrip" = list(
			"shrink" = 0.6,
			"sx" = 4,
			"sy" = 0,
			"nx" = -7,
			"ny" = 1,
			"wx" = -8,
			"wy" = 0,
			"ex" = 8,
			"ey" = -1,
			"northabove" = 0,
			"southabove" = 1,
			"eastabove" = 1,
			"westabove" = 0,
			"nturn" = -135,
			"sturn" = -35,
			"wturn" = 45,
			"eturn" = 145,
			"nflip" = 8,
			"sflip" = 8,
			"wflip" = 1,
			"eflip" = 0,
		),
	)
	var_overrides = list(
		"wlength" = WLENGTH_NORMAL
	)

/datum/alt_grip/mordhau/broadsword/forgotten_blade
	grip_intents = list(
		/datum/intent/effect/daze,
		/datum/intent/sword/strike,
		/datum/intent/sword/bash
	)
	onmobprop_overrides = list(
		"altgrip" = list(
			"shrink" = 0.6,
			"sx" = 4,
			"sy" = 0,
			"nx" = -7,
			"ny" = 1,
			"wx" = -8,
			"wy" = 0,
			"ex" = 8,
			"ey" = -1,
			"northabove" = 0,
			"southabove" = 1,
			"eastabove" = 1,
			"westabove" = 0,
			"nturn" = -135,
			"sturn" = -35,
			"wturn" = 45,
			"eturn" = 145,
			"nflip" = 8,
			"sflip" = 8,
			"wflip" = 1,
			"eflip" = 0,
		),
	)
	var_overrides = null

/datum/alt_grip/mordhau/broadsword/dream_broadsword
	grip_intents = list(
		/datum/intent/effect/daze,
		/datum/intent/sword/strike,
		/datum/intent/sword/bash
	)
	onmobprop_overrides = list(
		"altgrip" = list(
			"shrink" = 0.6,
			"sx" = 4,
			"sy" = 0,
			"nx" = -7,
			"ny" = 1,
			"wx" = -8,
			"wy" = 0,
			"ex" = 8,
			"ey" = -1,
			"northabove" = 0,
			"southabove" = 1,
			"eastabove" = 1,
			"westabove" = 0,
			"nturn" = -135,
			"sturn" = -35,
			"wturn" = 45,
			"eturn" = 145,
			"nflip" = 8,
			"sflip" = 8,
			"wflip" = 1,
			"eflip" = 0,
		),
	)
	var_overrides = null
